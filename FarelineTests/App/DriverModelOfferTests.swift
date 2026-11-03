import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelOfferTests {
    private let time = ManualTimeSource()

    @Test func ignoredOfferExpiresAndTheDriverStaysAvailable() async throws {
        let service = MockRideService.forModelTests(time: time)
        let ride = TestFixtures.ride()
        await service.addRide(ride)
        let model = DriverModel(service: service)
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        await model.goOnline()
        try await service.offerRide(id: ride.id)
        await waitUntil { model.session?.pendingOffer != nil }
        #expect(model.session?.pendingOffer?.ride.id == ride.id)

        await time.waitForSleeper()
        time.advance(by: 30)
        await waitUntil { model.session?.pendingOffer == nil }

        #expect(model.session?.driver.availability == .available)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }

    @Test func offerExpiringWhileAnAcceptIsInFlightDoesntTakeTheRide() async throws {
        let service = MockRideService.forModelTests(time: time, responseDelay: 1)
        let ride = TestFixtures.ride()
        await service.addRide(ride)
        let model = DriverModel(service: service)
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        let goingOnline = Task { await model.goOnline() }
        await time.waitForSleeper()
        time.advance(by: 1)
        await goingOnline.value

        try await service.offerRide(id: ride.id)
        await waitUntil { model.session?.pendingOffer != nil }
        let offerID = try #require(model.session?.pendingOffer?.id)

        // The accept is sent just before the expiry. The two timers are advanced separately, so the offer
        // always expires first and the test always takes the same path.
        await time.waitForSleeper()
        time.advance(by: 29.5)
        let accepting = Task { await model.acceptOffer(id: offerID) }
        await time.waitForSleeper(count: 2)
        time.advance(by: 0.5)
        await waitUntil { model.session?.pendingOffer == nil }
        time.advance(by: 0.5)
        await accepting.value

        #expect(model.lastError == .offerNoLongerAvailable)
        #expect(model.session?.activeRide == nil)
        #expect(model.session?.driver.availability == .available)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }
}
