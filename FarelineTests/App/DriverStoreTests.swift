import Foundation
import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverStoreTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()

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

    /// Returns a store whose driver has a pending offer for the fixture ride.
    private func makeStoreWithOffer(service: MockRideService) async throws -> DriverStore {
        let store = DriverStore(service: service)
        await service.addRide(ride)
        store.apply(try await service.goOnline())
        try await service.offerRide(id: ride.id)
        for await session in await service.sessionUpdates() {
            store.apply(session)
            break
        }
        return store
    }

    private func makeSession(version: Int) -> DriverSession {
        DriverSession(
            version: version,
            driver: Driver(id: TestFixtures.driverID, name: PersonNameComponents()),
            pendingOffer: nil,
            activeRide: nil,
            completedRides: []
        )
    }

    /// Waits for a condition on the store, without relying on delays.
    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async {
        for await isMet in Observations(condition) where isMet {
            return
        }
    }

    @Test func startReceivesSessionsFromTheService() async {
        let store = DriverStore(service: makeService())

        let task = Task { await store.start() }
        await waitUntil { store.session != nil }
        task.cancel()

        #expect(store.session?.driver.availability == .offline)
    }

    @Test func goingOnlineUpdatesTheSession() async {
        let store = DriverStore(service: makeService())

        await store.goOnline()

        #expect(store.session?.driver.availability == .available)
        #expect(store.lastError == nil)
    }

    @Test func acceptingUpdatesTheSession() async throws {
        let store = try await makeStoreWithOffer(service: makeService())

        await store.acceptPendingOffer()

        #expect(store.session?.pendingOffer == nil)
        #expect(store.session?.activeRide?.id == ride.id)
        #expect(store.session?.driver.availability == .onRide)
    }

    @Test func decliningClearsTheOfferAndLeavesTheRideAvailable() async throws {
        let service = makeService()
        let store = try await makeStoreWithOffer(service: service)

        await store.declinePendingOffer()

        #expect(store.session?.pendingOffer == nil)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }

    @Test func rideProgressesToCompletion() async throws {
        let store = try await makeStoreWithOffer(service: makeService())
        await store.acceptPendingOffer()

        await store.markArrived()
        #expect(store.session?.activeRide?.status == .driverArrived)

        await store.startTrip()
        #expect(store.session?.activeRide?.status == .inProgress)

        await store.completeTrip()
        #expect(store.session?.activeRide == nil)
        #expect(store.session?.completedRides.map(\.id) == [ride.id])
    }

    @Test func failedRequestKeepsTheSessionAndRecordsTheError() async throws {
        let service = makeService()
        let store = try await makeStoreWithOffer(service: service)
        let original = store.session
        await service.failNextRequest(with: .networkUnavailable)

        await store.acceptPendingOffer()

        #expect(store.session == original)
        #expect(store.lastError == .networkUnavailable)
        #expect(store.isPerformingAction == false)
    }

    @Test func nextActionClearsThePreviousError() async throws {
        let service = makeService()
        let store = try await makeStoreWithOffer(service: service)
        await service.failNextRequest(with: .networkUnavailable)
        await store.acceptPendingOffer()

        await store.acceptPendingOffer()

        #expect(store.lastError == nil)
        #expect(store.session?.activeRide?.id == ride.id)
    }

    @Test func dismissingClearsTheError() async {
        let service = makeService()
        let store = DriverStore(service: service)
        await service.failNextRequest(with: .networkUnavailable)
        await store.goOnline()
        #expect(store.lastError == .networkUnavailable)

        store.dismissError()

        #expect(store.lastError == nil)
    }

    @Test func olderSessionIsIgnored() {
        let store = DriverStore(service: makeService())

        store.apply(makeSession(version: 5))
        store.apply(makeSession(version: 3))

        #expect(store.session?.version == 5)
    }

    @Test func secondTapIsIgnoredWhileARequestIsInProgress() async throws {
        let service = makeService(responseDelay: 1)
        let store = DriverStore(service: service)

        let firstTap = Task { await store.goOnline() }
        await waitUntil { store.isPerformingAction }

        // A second request would fail, as the driver can't go online twice, and record an error.
        await store.goOnline()
        #expect(store.isPerformingAction)

        await time.waitForSleeper()
        time.advance(by: 1)
        await firstTap.value

        #expect(store.session?.driver.availability == .available)
        #expect(store.lastError == nil)
    }

    @Test func actionsWithNothingToActOnDoNothing() async {
        let store = DriverStore(service: makeService())

        await store.acceptPendingOffer()
        await store.declinePendingOffer()
        await store.markArrived()
        await store.startTrip()
        await store.completeTrip()

        #expect(store.session == nil)
        #expect(store.lastError == nil)
    }
}
