import Foundation
import Testing
@testable import Fareline

/// Covers the driver taking a ride from the waiting list themselves.
@Suite(.timeLimit(.minutes(1)))
struct MockRideServiceClaimTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()

    /// Returns a service whose waiting list starts with the given rides.
    private func makeService(waitingRides: [Ride]) -> MockRideService {
        MockRideService(
            configuration: MockRideServiceConfiguration(
                offerDelay: nil,
                offerLifetime: MockRideServiceTests.offerLifetime,
                responseDelay: 0
            ),
            timeSource: time,
            driver: Driver(id: TestFixtures.driverID, name: PersonNameComponents()),
            waitingRides: waitingRides
        )
    }

    /// Returns a ride from the mock data whose rider cancels after a driver takes it.
    private func cancellingRide() -> Ride? {
        (0..<10)
            .map { MockRideData.makeRide(sequence: $0, requestedAt: time.now) }
            .first { MockRideData.riderCancellationDelay(for: $0) != nil }
    }

    @Test func claimingAWaitingRideStartsIt() async throws {
        let service = makeService(waitingRides: [ride])
        _ = try await service.goOnline()

        let session = try await service.claimRide(rideID: ride.id)

        #expect(session.activeRide?.id == ride.id)
        #expect(session.activeRide?.status == .driverEnRoute)
        #expect(session.activeRide?.driverID == TestFixtures.driverID)
        #expect(session.driver.availability == .onRide)
        #expect(session.waitingRides.isEmpty)
    }

    @Test func claimingSchedulesTheRidersOwnCancellation() async throws {
        let ride = try #require(cancellingRide())
        let delay = try #require(MockRideData.riderCancellationDelay(for: ride))
        let service = makeService(waitingRides: [ride])
        _ = try await service.goOnline()
        _ = try await service.claimRide(rideID: ride.id)
        await time.waitForSleeper()

        time.advance(by: delay)

        for await session in await service.sessionUpdates() where session.activeRide == nil {
            #expect(session.pastRides.first?.cancelledBy == .rider)
            break
        }
    }

    @Test func claimingWhileOfflineIsRefused() async throws {
        let service = makeService(waitingRides: [ride])

        await #expect(throws: RideServiceError.actionNotAllowed) {
            try await service.claimRide(rideID: ride.id)
        }

        let session = try await service.currentSession()
        #expect(session.waitingRides.map(\.id) == [ride.id])
        #expect(session.driver.availability == .offline)
    }

    @Test func claimingWhileOnARideIsRefused() async throws {
        let other = Ride(
            id: UUID(testValue: 30),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        let service = makeService(waitingRides: [ride, other])
        _ = try await service.goOnline()
        _ = try await service.claimRide(rideID: ride.id)

        await #expect(throws: RideServiceError.actionNotAllowed) {
            try await service.claimRide(rideID: other.id)
        }

        let session = try await service.currentSession()
        #expect(session.activeRide?.id == ride.id)
        #expect(session.waitingRides.map(\.id) == [other.id])
    }

    @Test func claimingWhileAnOfferIsPendingDeclinesTheOffer() async throws {
        let offered = Ride(
            id: UUID(testValue: 31),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        let service = makeService(waitingRides: [ride])
        await service.addRide(offered)
        _ = try await service.goOnline()
        try await service.offerRide(id: offered.id)

        let session = try await service.claimRide(rideID: ride.id)

        #expect(session.pendingOffer == nil)
        #expect(session.activeRide?.id == ride.id)
        // The driver chose another ride, so the offered one is still waiting for someone to take it.
        #expect(session.waitingRides.map(\.id) == [offered.id])
    }

    @Test func claimingTheOfferedRideFails() async throws {
        let service = makeService(waitingRides: [])
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)

        // An offered ride isn't in the list, so the driver answers its offer instead.
        await #expect(throws: RideServiceError.rideNoLongerWaiting) {
            try await service.claimRide(rideID: ride.id)
        }

        let session = try await service.currentSession()
        #expect(session.pendingOffer?.ride.id == ride.id)
        #expect(session.driver.availability == .available)
    }

    @Test func failedClaimChangesNothing() async throws {
        let service = makeService(waitingRides: [ride])
        _ = try await service.goOnline()
        await service.failNextRequest(with: .networkUnavailable)

        await #expect(throws: RideServiceError.networkUnavailable) {
            try await service.claimRide(rideID: ride.id)
        }

        let session = try await service.currentSession()
        #expect(session.activeRide == nil)
        #expect(session.driver.availability == .available)
        #expect(session.waitingRides.map(\.id) == [ride.id])
    }

    @Test func claimingARideAnotherDriverTookFails() async throws {
        let service = makeService(waitingRides: [ride])
        _ = try await service.goOnline()
        try await service.simulateRideTaken(id: ride.id, byDriverID: UUID(testValue: 50))

        await #expect(throws: RideServiceError.rideNoLongerWaiting) {
            try await service.claimRide(rideID: ride.id)
        }

        let session = try await service.currentSession()
        #expect(session.activeRide == nil)
        #expect(session.driver.availability == .available)
    }

    @Test func claimingARideWhoseRiderCancelledFails() async throws {
        let service = makeService(waitingRides: [ride])
        _ = try await service.goOnline()
        try await service.simulateRideCancelled(id: ride.id)

        await #expect(throws: RideServiceError.rideNoLongerWaiting) {
            try await service.claimRide(rideID: ride.id)
        }

        #expect(try await service.currentSession().driver.availability == .available)
    }

    @Test func claimingTaylorTakensRideFailsAsTakenByAnotherDriver() async throws {
        let seeded = MockRideData.passedOverRides(at: time.now)
        let taylor = try #require(seeded.first { $0.rider.name.familyName == "Taken" })
        let service = makeService(waitingRides: seeded)
        _ = try await service.goOnline()

        await #expect(throws: RideServiceError.rideNoLongerWaiting) {
            try await service.claimRide(rideID: taylor.id)
        }

        let session = try await service.currentSession()
        #expect(session.waitingRides.contains { $0.id == taylor.id } == false)
        #expect(session.activeRide == nil)
        #expect(await service.ride(id: taylor.id)?.status == .driverEnRoute)
    }
}
