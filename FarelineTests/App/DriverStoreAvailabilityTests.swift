import Foundation
import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverStoreAvailabilityTests {
    private let time = ManualTimeSource()

    /// Returns a store whose driver has accepted a ride and is on it.
    private func makeStoreOnARide(service: MockRideService) async throws -> DriverStore {
        let ride = TestFixtures.ride()
        let store = DriverStore(service: service)
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)
        for await session in await service.sessionUpdates() {
            store.apply(session)
            break
        }
        await store.acceptOffer(id: try #require(store.session?.pendingOffer?.id))
        return store
    }

    /// Lets a request's simulated response delay finish.
    private func finish(_ request: Task<Void, Never>) async {
        await time.waitForSleeper()
        time.advance(by: 1)
        await request.value
    }

    @Test func failedChangeKeepsTheStatusAndShowsAnError() async {
        let service = MockRideService.forStoreTests(time: time)
        let store = DriverStore(service: service)
        await store.goOnline()
        await service.failNextRequest(with: .networkUnavailable)

        await store.goOffline()

        #expect(store.session?.driver.availability == .available)
        #expect(store.isShowingError)
    }

    @Test func dismissingTheAlertClearsTheError() async {
        let service = MockRideService.forStoreTests(time: time)
        let store = DriverStore(service: service)
        await service.failNextRequest(with: .networkUnavailable)
        await store.goOnline()

        store.isShowingError = false

        #expect(store.lastError == nil)
    }

    @Test func availabilityCantChangeBeforeTheFirstSession() {
        let store = DriverStore(service: MockRideService.forStoreTests(time: time))

        #expect(store.canChangeAvailability == false)
    }

    @Test func availabilityCantChangeWhileARequestIsInProgress() async {
        let store = DriverStore(service: MockRideService.forStoreTests(time: time, responseDelay: 1))
        await finish(Task { await store.goOnline() })
        #expect(store.canChangeAvailability)

        let request = Task { await store.goOffline() }
        await waitUntil { store.isPerformingAction }
        #expect(store.canChangeAvailability == false)

        await finish(request)
        #expect(store.canChangeAvailability)
    }

    @Test func availabilityCantChangeDuringARide() async throws {
        let store = try await makeStoreOnARide(service: .forStoreTests(time: time))

        #expect(store.canChangeAvailability == false)
    }
}
