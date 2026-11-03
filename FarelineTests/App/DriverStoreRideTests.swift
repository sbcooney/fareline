import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverStoreRideTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()
    private let service: MockRideService
    private let store: DriverStore

    init() {
        service = .forStoreTests(time: time)
        store = DriverStore(service: service)
    }

    /// Puts the driver on the fixture ride.
    private func startRide() async throws {
        await service.addRide(ride)
        await store.goOnline()
        try await service.offerRide(id: ride.id)
        store.apply(try await currentSession())
        await store.acceptOffer(id: try #require(store.session?.pendingOffer?.id))
        try #require(store.session?.activeRide?.id == ride.id)
    }

    private func currentSession() async throws -> DriverSession {
        for await session in await service.sessionUpdates() {
            return session
        }
        throw CancellationError()
    }

    @Test func rideProgressesToCompletion() async throws {
        try await startRide()

        await store.markArrived(rideID: ride.id)
        #expect(store.session?.activeRide?.status == .driverArrived)

        await store.startTrip(rideID: ride.id)
        #expect(store.session?.activeRide?.status == .inProgress)

        await store.completeTrip(rideID: ride.id)
        #expect(store.session?.activeRide == nil)
        #expect(store.session?.driver.availability == .available)
        #expect(store.session?.pastRides.map(\.id) == [ride.id])
        #expect(store.cancelledRide == nil)
    }

    @Test func failedStepKeepsTheRideAndCanBeRetried() async throws {
        try await startRide()
        await service.failNextRequest(with: .networkUnavailable)

        await store.markArrived(rideID: ride.id)
        #expect(store.lastError == .networkUnavailable)
        #expect(store.session?.activeRide?.status == .driverEnRoute)

        await store.markArrived(rideID: ride.id)
        #expect(store.lastError == nil)
        #expect(store.session?.activeRide?.status == .driverArrived)
    }

    @Test func riderCancellingIsShownToTheDriver() async throws {
        try await startRide()
        let updates = Task { await store.start() }
        defer { updates.cancel() }

        try await service.simulateRideCancelled(id: ride.id)
        await waitUntil { store.cancelledRide != nil }

        #expect(store.cancelledRide?.id == ride.id)
        #expect(store.session?.activeRide == nil)
        #expect(store.session?.driver.availability == .available)
    }

    @Test func cancellationIsShownEvenIfTheStoreNeverSawTheRideActive() async throws {
        await service.addRide(ride)
        await store.goOnline()
        try await service.offerRide(id: ride.id)
        store.apply(try await currentSession())
        let offer = try #require(store.session?.pendingOffer)
        _ = try await service.acceptOffer(id: offer.id)
        try await service.simulateRideCancelled(id: ride.id)

        store.apply(try await currentSession())

        #expect(store.cancelledRide?.id == ride.id)
    }

    @Test func pastRidesInTheFirstSessionArentReportedAsCancellations() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        let newStore = DriverStore(service: service)

        newStore.apply(try await currentSession())

        #expect(newStore.cancelledRide == nil)
    }

    @Test func dismissingTheCancellationClearsIt() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        store.apply(try await currentSession())
        #expect(store.isShowingCancelledRide)

        store.isShowingCancelledRide = false

        #expect(store.cancelledRide == nil)
    }

    @Test func stepTappedAfterTheRiderCancelledShowsOnlyTheCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        store.apply(try await currentSession())

        await store.markArrived(rideID: ride.id)

        #expect(store.cancelledRide?.id == ride.id)
        #expect(store.lastError == nil)
    }

    @Test func stepThatFailedBeforeTheCancellationArrivedShowsOnlyTheCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        await store.markArrived(rideID: ride.id)
        #expect(store.lastError == .rideNoLongerAvailable)

        store.apply(try await currentSession())

        #expect(store.cancelledRide?.id == ride.id)
        #expect(store.lastError == nil)
    }
}
