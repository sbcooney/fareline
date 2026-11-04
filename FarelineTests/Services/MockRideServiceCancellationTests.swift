import Foundation
import Testing
@testable import Fareline

/// Covers a ride ending early, whether the driver or the rider cancels it.
@Suite(.timeLimit(.minutes(1)))
struct MockRideServiceCancellationTests {
    /// How far the driver got before cancelling.
    enum Stage: CaseIterable {
        case headingToPickup, atPickup, onTrip
    }

    private let time = ManualTimeSource()
    private let service: MockRideService
    private let ride = TestFixtures.ride()

    init() {
        service = MockRideServiceTests.makeService(time: time, offerDelay: nil)
    }

    /// Puts the driver on the given ride.
    private func startRide(_ ride: Ride) async throws {
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)
        let offer = try #require(await service.currentSession().pendingOffer)
        _ = try await service.acceptOffer(id: offer.id)
    }

    /// Takes the driver's ride to the given stage.
    private func advance(_ ride: Ride, to stage: Stage) async throws {
        if stage == .atPickup || stage == .onTrip {
            _ = try await service.markArrived(rideID: ride.id)
        }
        if stage == .onTrip {
            _ = try await service.startTrip(rideID: ride.id)
        }
    }

    /// Returns a ride from the mock data whose rider cancels after the driver accepts.
    private func cancellingRide() -> Ride? {
        (0..<10)
            .map { MockRideData.makeRide(sequence: $0, requestedAt: time.now) }
            .first { MockRideData.riderCancellationDelay(for: $0) != nil }
    }

    @Test(arguments: Stage.allCases)
    func driverCancellingRecordsItAndFreesTheDriver(stage: Stage) async throws {
        try await startRide(ride)
        try await advance(ride, to: stage)

        let session = try await service.cancelRide(rideID: ride.id)

        #expect(session.activeRide == nil)
        #expect(session.driver.availability == .available)
        let ended = try #require(session.pastRides.first)
        #expect(ended.id == ride.id)
        #expect(ended.status == .cancelled)
        #expect(ended.cancelledBy == .driver)
        #expect(ended.endedAt == time.now)
    }

    @Test(arguments: [Stage.headingToPickup, .atPickup])
    func driverCancellingBeforeTheTripGivesTheRiderANewRequest(stage: Stage) async throws {
        try await startRide(ride)
        try await advance(ride, to: stage)
        time.advance(by: 120)

        let session = try await service.cancelRide(rideID: ride.id)

        let request = try #require(session.waitingRides.first)
        #expect(session.waitingRides.count == 1)
        #expect(request.id != ride.id)
        #expect(request.rider == ride.rider)
        #expect(request.pickup == ride.pickup)
        #expect(request.dropoff == ride.dropoff)
        #expect(request.fare == ride.fare)
        // The rider has been waiting since their first request, so the new one keeps that time.
        #expect(request.requestedAt == ride.requestedAt)
        #expect(request.status == .awaitingDriver)
        #expect(session.pastRides.first?.id == ride.id)
        #expect(session.pastRides.first?.cancelledBy == .driver)
    }

    @Test func driverCancellingDuringTheTripDoesntListTheRider() async throws {
        try await startRide(ride)
        try await advance(ride, to: .onTrip)

        let session = try await service.cancelRide(rideID: ride.id)

        // The rider was already in the car, so the ride is over.
        #expect(session.waitingRides.isEmpty)
    }

    @Test func cancellingARideThatIsntCurrentIsRejected() async throws {
        try await startRide(ride)

        await #expect(throws: RideServiceError.rideNoLongerAvailable) {
            try await service.cancelRide(rideID: UUID(testValue: 99))
        }

        let session = try await service.currentSession()
        #expect(session.activeRide?.id == ride.id)
        #expect(session.driver.availability == .onRide)
    }

    @Test func failedCancellationLeavesTheRideAsItWas() async throws {
        try await startRide(ride)
        try await advance(ride, to: .atPickup)
        await service.failNextRequest(with: .networkUnavailable)

        await #expect(throws: RideServiceError.networkUnavailable) {
            try await service.cancelRide(rideID: ride.id)
        }

        let session = try await service.currentSession()
        #expect(session.activeRide?.status == .driverArrived)
        #expect(session.driver.availability == .onRide)
        #expect(session.pastRides.isEmpty)
    }

    @Test func driverCantCancelARideTheRiderAlreadyCancelled() async throws {
        try await startRide(ride)
        try await service.simulateRideCancelled(id: ride.id)

        await #expect(throws: RideServiceError.rideNoLongerAvailable) {
            try await service.cancelRide(rideID: ride.id)
        }

        let pastRides = try await service.currentSession().pastRides
        #expect(pastRides.map(\.id) == [ride.id])
        #expect(pastRides.first?.cancelledBy == .rider)
    }

    @Test func riderCancellationAfterTheDriverCancelledHasNoEffect() async throws {
        let ride = try #require(cancellingRide())
        let delay = try #require(MockRideData.riderCancellationDelay(for: ride))
        try await startRide(ride)
        await time.waitForSleeper()

        _ = try await service.cancelRide(rideID: ride.id)
        time.advance(by: delay)

        let pastRides = try await service.currentSession().pastRides
        #expect(pastRides.map(\.id) == [ride.id])
        #expect(pastRides.first?.cancelledBy == .driver)
    }

    @Test func riderCancellingAtPickupRecordsItAndFreesTheDriver() async throws {
        let ride = try #require(cancellingRide())
        let delay = try #require(MockRideData.riderCancellationDelay(for: ride))
        try await startRide(ride)
        await time.waitForSleeper()
        try await advance(ride, to: .atPickup)

        time.advance(by: delay)

        for await session in await service.sessionUpdates() where session.activeRide == nil {
            #expect(session.driver.availability == .available)
            let ended = try #require(session.pastRides.first)
            #expect(ended.id == ride.id)
            #expect(ended.status == .cancelled)
            #expect(ended.cancelledBy == .rider)
            break
        }
    }
}
