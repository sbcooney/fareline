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
}
