import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelRideTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()
    private let service: MockRideService
    private let model: DriverModel

    init() {
        service = .forModelTests(time: time)
        model = DriverModel(service: service)
    }

    /// Puts the driver on the fixture ride.
    private func startRide() async throws {
        await service.addRide(ride)
        await model.goOnline()
        try await service.offerRide(id: ride.id)
        model.apply(try await currentSession())
        await model.acceptOffer(id: try #require(model.session?.pendingOffer?.id))
        try #require(model.session?.activeRide?.id == ride.id)
    }

    private func currentSession() async throws -> DriverSession {
        for await session in await service.sessionUpdates() {
            return session
        }
        throw CancellationError()
    }

    @Test func rideProgressesToCompletion() async throws {
        try await startRide()

        await model.markArrived(rideID: ride.id)
        #expect(model.session?.activeRide?.status == .driverArrived)

        await model.startTrip(rideID: ride.id)
        #expect(model.session?.activeRide?.status == .inProgress)

        await model.completeTrip(rideID: ride.id)
        #expect(model.session?.activeRide == nil)
        #expect(model.session?.driver.availability == .available)
        #expect(model.session?.pastRides.map(\.id) == [ride.id])
        #expect(model.cancelledRide == nil)
    }

    @Test func failedStepKeepsTheRideAndCanBeRetried() async throws {
        try await startRide()
        await service.failNextRequest(with: .networkUnavailable)

        await model.markArrived(rideID: ride.id)
        #expect(model.lastError == .networkUnavailable)
        #expect(model.session?.activeRide?.status == .driverEnRoute)

        await model.markArrived(rideID: ride.id)
        #expect(model.lastError == nil)
        #expect(model.session?.activeRide?.status == .driverArrived)
    }

    @Test func riderCancellingIsShownToTheDriver() async throws {
        try await startRide()
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        try await service.simulateRideCancelled(id: ride.id)
        await waitUntil { model.cancelledRide != nil }

        #expect(model.cancelledRide?.id == ride.id)
        #expect(model.session?.activeRide == nil)
        #expect(model.session?.driver.availability == .available)
    }

    @Test func cancellationIsShownEvenIfTheModelNeverSawTheRideActive() async throws {
        await service.addRide(ride)
        await model.goOnline()
        try await service.offerRide(id: ride.id)
        model.apply(try await currentSession())
        let offer = try #require(model.session?.pendingOffer)
        _ = try await service.acceptOffer(id: offer.id)
        try await service.simulateRideCancelled(id: ride.id)

        model.apply(try await currentSession())

        #expect(model.cancelledRide?.id == ride.id)
    }

    @Test func pastRidesInTheFirstSessionArentReportedAsCancellations() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        let newModel = DriverModel(service: service)

        newModel.apply(try await currentSession())

        #expect(newModel.cancelledRide == nil)
    }

    @Test func dismissingTheCancellationClearsIt() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await currentSession())
        #expect(model.isShowingCancelledRide)

        model.isShowingCancelledRide = false

        #expect(model.cancelledRide == nil)
    }

    @Test func stepTappedAfterTheRiderCancelledShowsOnlyTheCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await currentSession())

        await model.markArrived(rideID: ride.id)

        #expect(model.cancelledRide?.id == ride.id)
        #expect(model.lastError == nil)
    }

    @Test func stepThatFailedBeforeTheCancellationArrivedShowsOnlyTheCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        await model.markArrived(rideID: ride.id)
        #expect(model.lastError == .rideNoLongerAvailable)

        model.apply(try await currentSession())

        #expect(model.cancelledRide?.id == ride.id)
        #expect(model.lastError == nil)
    }
}
