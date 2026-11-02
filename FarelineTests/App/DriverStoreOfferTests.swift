import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverStoreOfferTests {
    private let time = ManualTimeSource()

    @Test func ignoredOfferExpiresAndTheDriverStaysAvailable() async throws {
        let service = MockRideService.forStoreTests(time: time)
        let ride = TestFixtures.ride()
        await service.addRide(ride)
        let store = DriverStore(service: service)
        let updates = Task { await store.start() }
        defer { updates.cancel() }

        await store.goOnline()
        try await service.offerRide(id: ride.id)
        await waitUntil { store.session?.pendingOffer != nil }
        #expect(store.session?.pendingOffer?.ride.id == ride.id)

        await time.waitForSleeper()
        time.advance(by: 30)
        await waitUntil { store.session?.pendingOffer == nil }

        #expect(store.session?.driver.availability == .available)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }

    @Test func offerExpiringWhileAnAcceptIsInFlightDoesntTakeTheRide() async throws {
        let service = MockRideService.forStoreTests(time: time, responseDelay: 1)
        let ride = TestFixtures.ride()
        await service.addRide(ride)
        let store = DriverStore(service: service)
        let updates = Task { await store.start() }
        defer { updates.cancel() }

        let goingOnline = Task { await store.goOnline() }
        await time.waitForSleeper()
        time.advance(by: 1)
        await goingOnline.value

        try await service.offerRide(id: ride.id)
        await waitUntil { store.session?.pendingOffer != nil }
        let offerID = try #require(store.session?.pendingOffer?.id)

        // The accept is sent just before the expiry, and its response arrives just after.
        await time.waitForSleeper()
        time.advance(by: 29.5)
        let accepting = Task { await store.acceptOffer(id: offerID) }
        await time.waitForSleeper(count: 2)
        time.advance(by: 1)
        await accepting.value
        await waitUntil { store.session?.pendingOffer == nil }

        #expect(store.lastError == .offerNoLongerAvailable)
        #expect(store.session?.activeRide == nil)
        #expect(store.session?.driver.availability == .available)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }
}
