import Foundation
import Testing
@testable import Fareline

/// Covers the repeating cycle that keeps an available driver receiving offers.
@Suite(.timeLimit(.minutes(1)))
struct MockRideServiceOfferLoopTests {
    private let time = ManualTimeSource()

    /// Returns a service whose driver is online with an automatic offer pending.
    private func makeServiceWithAutomaticOffer() async throws -> (MockRideService, RideOffer) {
        let service = MockRideServiceTests.makeService(time: time, offerDelay: 5)
        _ = try await service.goOnline()
        time.advance(by: 5)
        return (service, try await waitForOffer(from: service))
    }

    /// Waits for a pending offer other than the one given.
    private func waitForOffer(
        from service: MockRideService,
        otherThan id: RideOffer.ID? = nil
    ) async throws -> RideOffer {
        for await session in await service.sessionUpdates() {
            if let offer = session.pendingOffer, offer.id != id {
                return offer
            }
        }
        throw RideServiceError.offerNoLongerAvailable
    }

    @Test func newOfferFollowsADecline() async throws {
        let (service, offer) = try await makeServiceWithAutomaticOffer()

        _ = try await service.declineOffer(id: offer.id)
        time.advance(by: 5)

        _ = try await waitForOffer(from: service, otherThan: offer.id)
    }

    @Test func newOfferFollowsAnExpiry() async throws {
        let (service, offer) = try await makeServiceWithAutomaticOffer()

        time.advance(by: MockRideServiceTests.offerLifetime)
        for await session in await service.sessionUpdates() where session.pendingOffer == nil {
            break
        }
        time.advance(by: 5)

        _ = try await waitForOffer(from: service, otherThan: offer.id)
    }

    @Test func newOfferFollowsACompletedRide() async throws {
        let (service, offer) = try await makeServiceWithAutomaticOffer()
        let rideID = offer.ride.id

        _ = try await service.acceptOffer(id: offer.id)
        _ = try await service.markArrived(rideID: rideID)
        _ = try await service.startTrip(rideID: rideID)
        _ = try await service.completeTrip(rideID: rideID)
        time.advance(by: 5)

        _ = try await waitForOffer(from: service, otherThan: offer.id)
    }

    @Test func newOfferFollowsADriverCancellation() async throws {
        let (service, offer) = try await makeServiceWithAutomaticOffer()

        _ = try await service.acceptOffer(id: offer.id)
        _ = try await service.cancelRide(rideID: offer.ride.id)
        time.advance(by: 5)

        _ = try await waitForOffer(from: service, otherThan: offer.id)
    }

    @Test func newOfferFollowsAWithdrawnOffer() async throws {
        let (service, offer) = try await makeServiceWithAutomaticOffer()

        try await service.simulateRideCancelled(id: offer.ride.id)
        time.advance(by: 5)

        _ = try await waitForOffer(from: service, otherThan: offer.id)
    }
}
