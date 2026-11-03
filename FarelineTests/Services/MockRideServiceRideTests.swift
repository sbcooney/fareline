import Foundation
import Testing
@testable import Fareline

/// Covers the driver's current ride, from accepting to completion or cancellation.
@Suite(.timeLimit(.minutes(1)))
struct MockRideServiceRideTests {
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

    /// Returns a ride from the mock data whose rider cancels after the driver accepts.
    private func cancellingRide() -> Ride? {
        (0..<10)
            .map { MockRideData.makeRide(sequence: $0, requestedAt: time.now) }
            .first { MockRideData.riderCancellationDelay(for: $0) != nil }
    }

    /// Waits for an update that happens on the service's own timers.
    private func waitForSession(where condition: (DriverSession) -> Bool) async -> DriverSession? {
        for await session in await service.sessionUpdates() where condition(session) {
            return session
        }
        return nil
    }

    @Test func completingARideRecordsItAndFreesTheDriver() async throws {
        try await startRide(ride)

        _ = try await service.markArrived(rideID: ride.id)
        _ = try await service.startTrip(rideID: ride.id)
        let session = try await service.completeTrip(rideID: ride.id)

        #expect(session.activeRide == nil)
        #expect(session.driver.availability == .available)
        #expect(session.pastRides.map(\.id) == [ride.id])
        #expect(session.pastRides.first?.endedAt == time.now)
    }

    @Test func duplicateCompletionIsRejected() async throws {
        try await startRide(ride)
        _ = try await service.markArrived(rideID: ride.id)
        _ = try await service.startTrip(rideID: ride.id)
        _ = try await service.completeTrip(rideID: ride.id)

        await #expect(throws: RideServiceError.rideNoLongerAvailable) {
            try await service.completeTrip(rideID: ride.id)
        }
        #expect(try await service.currentSession().pastRides.count == 1)
    }

    @Test func invalidStepLeavesTheRideUnchanged() async throws {
        try await startRide(ride)

        await #expect(throws: RideServiceError.actionNotAllowed) {
            try await service.completeTrip(rideID: ride.id)
        }

        let session = try await service.currentSession()
        #expect(session.activeRide?.status == .driverEnRoute)
        #expect(session.driver.availability == .onRide)
    }

    @Test func cancellingTheCurrentRideRecordsItAndFreesTheDriver() async throws {
        try await startRide(ride)

        try await service.simulateRideCancelled(id: ride.id)

        let session = try await service.currentSession()
        #expect(session.activeRide == nil)
        #expect(session.driver.availability == .available)
        #expect(session.pastRides.map(\.id) == [ride.id])
        #expect(session.pastRides.first?.status == .cancelled)
        #expect(session.pastRides.first?.endedAt == time.now)
    }

    @Test func pastRidesAreNewestFirstByWhenTheyEnded() async throws {
        try await startRide(ride)
        _ = try await service.markArrived(rideID: ride.id)
        _ = try await service.startTrip(rideID: ride.id)
        _ = try await service.completeTrip(rideID: ride.id)

        time.advance(by: 60)
        let cancelledRide = Ride(
            id: UUID(testValue: 11),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        await service.addRide(cancelledRide)
        try await service.offerRide(id: cancelledRide.id)
        let offer = try #require(await service.currentSession().pendingOffer)
        _ = try await service.acceptOffer(id: offer.id)
        try await service.simulateRideCancelled(id: cancelledRide.id)

        let pastRides = try await service.currentSession().pastRides
        #expect(pastRides.map(\.id) == [cancelledRide.id, ride.id])
        #expect(pastRides.map(\.status) == [.cancelled, .completed])
        #expect(pastRides.compactMap(\.endedAt) == [time.now, time.now.addingTimeInterval(-60)])
    }

    @Test func riderWhoCancelsDoesSoAfterTheDriverAccepts() async throws {
        let ride = try #require(cancellingRide())
        let delay = try #require(MockRideData.riderCancellationDelay(for: ride))
        try await startRide(ride)
        // Accepting ends the offer's expiry timer, so the only sleeper left is the cancellation.
        await time.waitForSleeper()
        time.advance(by: delay)

        let session = await waitForSession { $0.activeRide == nil }
        #expect(session?.pastRides.first?.id == ride.id)
        #expect(session?.pastRides.first?.status == .cancelled)
        #expect(session?.driver.availability == .available)
    }

    @Test func riderWhoCancelsCantOnceTheTripHasStarted() async throws {
        let ride = try #require(cancellingRide())
        let delay = try #require(MockRideData.riderCancellationDelay(for: ride))
        try await startRide(ride)
        await time.waitForSleeper()

        _ = try await service.markArrived(rideID: ride.id)
        _ = try await service.startTrip(rideID: ride.id)
        time.advance(by: delay)
        let session = try await service.completeTrip(rideID: ride.id)

        #expect(session.pastRides.first?.status == .completed)
    }

    @Test func lateCancellationOfAnEarlierRideDoesntAffectTheCurrentRide() async throws {
        try await startRide(ride)
        _ = try await service.markArrived(rideID: ride.id)
        _ = try await service.startTrip(rideID: ride.id)
        _ = try await service.completeTrip(rideID: ride.id)

        let nextRide = Ride(
            id: UUID(testValue: 10),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        await service.addRide(nextRide)
        try await service.offerRide(id: nextRide.id)
        let offer = try #require(await service.currentSession().pendingOffer)
        _ = try await service.acceptOffer(id: offer.id)

        await #expect(throws: RideServiceError.rideNoLongerAvailable) {
            try await service.simulateRideCancelled(id: ride.id)
        }

        let session = try await service.currentSession()
        #expect(session.activeRide?.id == nextRide.id)
        #expect(session.driver.availability == .onRide)
    }
}
