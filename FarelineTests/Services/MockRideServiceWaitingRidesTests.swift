import Foundation
import Testing
@testable import Fareline

/// Covers the list of waiting rides that no driver took.
@Suite(.timeLimit(.minutes(1)))
struct MockRideServiceWaitingRidesTests {
    private let time = ManualTimeSource()
    private let service: MockRideService
    private let ride = TestFixtures.ride()

    init() {
        service = MockRideServiceTests.makeService(time: time, offerDelay: nil)
    }

    /// Returns a copy of the fixture ride with a new ID, requested the given number of seconds before now.
    private func waitingRide(id: UInt8, requestedSecondsAgo seconds: TimeInterval) -> Ride {
        Ride(
            id: UUID(testValue: id),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now.addingTimeInterval(-seconds)
        )
    }

    /// Offers a ride to the driver, who is online, and declines it.
    private func offerAndDecline(_ ride: Ride) async throws {
        await service.addRide(ride)
        try await service.offerRide(id: ride.id)
        let offer = try #require(await service.currentSession().pendingOffer)
        _ = try await service.declineOffer(id: offer.id)
    }

    @Test func offeredRideIsntInTheList() async throws {
        await service.addRide(ride)
        _ = try await service.goOnline()

        try await service.offerRide(id: ride.id)

        #expect(try await service.currentSession().waitingRides.isEmpty)
    }

    @Test func declinedRideJoinsTheList() async throws {
        _ = try await service.goOnline()

        try await offerAndDecline(ride)

        #expect(try await service.currentSession().waitingRides.map(\.id) == [ride.id])
    }

    @Test func expiredOfferRideJoinsTheList() async throws {
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)

        time.advance(by: MockRideServiceTests.offerLifetime)

        for await session in await service.sessionUpdates() where session.pendingOffer == nil {
            #expect(session.waitingRides.map(\.id) == [ride.id])
            break
        }
    }

    @Test func offerEndedByGoingOfflineJoinsTheList() async throws {
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)

        let session = try await service.goOffline()

        #expect(session.waitingRides.map(\.id) == [ride.id])
    }

    @Test func listIsLongestWaitFirst() async throws {
        let recent = waitingRide(id: 10, requestedSecondsAgo: 60)
        let oldest = waitingRide(id: 11, requestedSecondsAgo: 600)
        let middle = waitingRide(id: 12, requestedSecondsAgo: 300)
        _ = try await service.goOnline()

        for ride in [recent, oldest, middle] {
            try await offerAndDecline(ride)
        }

        #expect(try await service.currentSession().waitingRides.map(\.id) == [oldest.id, middle.id, recent.id])
    }

    @Test func rideTakenByAnotherDriverLeavesTheList() async throws {
        _ = try await service.goOnline()
        try await offerAndDecline(ride)

        try await service.simulateRideTaken(id: ride.id, byDriverID: UUID(testValue: 50))

        #expect(try await service.currentSession().waitingRides.isEmpty)
    }

    @Test func rideCancelledByItsRiderLeavesTheList() async throws {
        _ = try await service.goOnline()
        try await offerAndDecline(ride)

        try await service.simulateRideCancelled(id: ride.id)

        #expect(try await service.currentSession().waitingRides.isEmpty)
    }

    @Test func rideInTheListIsntOfferedAgain() async throws {
        _ = try await service.goOnline()
        try await offerAndDecline(ride)

        // The driver can already see and take it, so offering it again would only repeat the list.
        await #expect(throws: RideServiceError.actionNotAllowed) {
            try await service.offerRide(id: ride.id)
        }
    }
}
