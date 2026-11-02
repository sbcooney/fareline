import Foundation
import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverStoreAvailabilityTests {
    private let time = ManualTimeSource()

    private func makeService(responseDelay: TimeInterval = 0) -> MockRideService {
        MockRideService(
            configuration: MockRideServiceConfiguration(
                offerDelay: nil,
                offerLifetime: 30,
                responseDelay: responseDelay
            ),
            timeSource: time,
            driver: Driver(
                id: TestFixtures.driverID,
                name: PersonNameComponents(givenName: "Grace", familyName: "Hopper")
            )
        )
    }

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

    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async {
        for await isMet in Observations(condition) where isMet {
            return
        }
    }

    @Test func changingSwitchesBetweenOfflineAndAvailable() async {
        let store = DriverStore(service: makeService())
        await store.goOnline()

        await store.changeAvailability()
        #expect(store.session?.driver.availability == .offline)

        await store.changeAvailability()
        #expect(store.session?.driver.availability == .available)
    }

    @Test func failedChangeKeepsTheStatusAndShowsAnError() async {
        let service = makeService()
        let store = DriverStore(service: service)
        await store.goOnline()
        await service.failNextRequest(with: .networkUnavailable)

        await store.changeAvailability()

        #expect(store.session?.driver.availability == .available)
        #expect(store.isShowingError)
    }

    @Test func dismissingTheAlertClearsTheError() async {
        let service = makeService()
        let store = DriverStore(service: service)
        await service.failNextRequest(with: .networkUnavailable)
        await store.goOnline()

        store.isShowingError = false

        #expect(store.lastError == nil)
    }

    @Test func availabilityCantChangeBeforeTheFirstSession() {
        let store = DriverStore(service: makeService())

        #expect(store.canChangeAvailability == false)
    }

    @Test func availabilityCantChangeWhileARequestIsInProgress() async {
        let store = DriverStore(service: makeService(responseDelay: 1))

        let request = Task { await store.goOnline() }
        await waitUntil { store.isPerformingAction }
        #expect(store.canChangeAvailability == false)

        await time.waitForSleeper()
        time.advance(by: 1)
        await request.value

        #expect(store.canChangeAvailability)
    }

    @Test func availabilityCantChangeDuringARide() async throws {
        let store = try await makeStoreOnARide(service: makeService())
        let original = store.session

        await store.changeAvailability()

        #expect(store.canChangeAvailability == false)
        #expect(store.session == original)
        #expect(store.lastError == nil)
    }
}
