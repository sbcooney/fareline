import Foundation
import Testing
@testable import Fareline

/// Covers what the model does when the connection drops and returns.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelOfflineTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()
    private let service: MockRideService
    private let model: DriverModel

    init() {
        service = .forModelTests(time: time)
        model = DriverModel(service: service)
    }

    @Test func modelFollowsTheConnection() async {
        let updates = Task { await model.start() }
        defer { updates.cancel() }
        await waitUntil { model.session != nil }
        #expect(model.isOffline == false)

        await service.setConnected(false)
        await waitUntil { model.isOffline }

        await service.setConnected(true)
        await waitUntil { model.isOffline == false }
    }

    /// Starts the model and waits until it knows it's offline.
    private func goOffline() async -> Task<Void, Never> {
        let updates = Task { await model.start() }
        await waitUntil { model.session != nil }
        await service.setConnected(false)
        await waitUntil { model.isOffline }
        return updates
    }

    @Test func actionNeedingAConnectionIsRefusedOfflineWithoutARequest() async throws {
        let updates = await goOffline()
        defer { updates.cancel() }

        await model.goOnline()

        // Sent, the request would fail with networkUnavailable and show an error.
        #expect(model.alert == nil)
        await service.setConnected(true)
        #expect(try await service.currentSession().driver.availability == .offline)
    }

    @Test func availabilityCantChangeOffline() async {
        let updates = await goOffline()
        defer { updates.cancel() }

        #expect(model.canChangeAvailability == false)
    }

    // MARK: - Queued ride steps

    /// Puts the driver on the fixture ride while online, then loses the connection.
    private func startRideThenGoOffline() async throws -> Task<Void, Never> {
        let updates = Task { await model.start() }
        await service.addRide(ride)
        await model.goOnline()
        try await service.offerRide(id: ride.id)
        model.apply(try await service.currentSession())
        await model.acceptOffer(id: try #require(model.session?.pendingOffer?.id))
        try #require(model.session?.activeRide?.id == ride.id)
        await service.setConnected(false)
        await waitUntil { model.isOffline }
        return updates
    }

    @Test func stepOfflineMovesTheRideOnAndQueuesWithoutARequest() async throws {
        let updates = try await startRideThenGoOffline()
        defer { updates.cancel() }

        await model.markArrived(rideID: ride.id)

        #expect(model.session?.activeRide?.status == .driverArrived)
        #expect(model.pendingSteps.map(\.event) == [.driverArrived])
        #expect(model.alert == nil)
        #expect(await service.ride(id: ride.id)?.status == .driverEnRoute)
    }

    @Test func completingOfflineEndsTheRideOnScreen() async throws {
        let updates = try await startRideThenGoOffline()
        defer { updates.cancel() }

        await model.markArrived(rideID: ride.id)
        await model.startTrip(rideID: ride.id)
        await model.completeTrip(rideID: ride.id)

        #expect(model.session?.activeRide == nil)
        #expect(model.session?.pastRides.first?.id == ride.id)
        #expect(model.session?.pastRides.first?.status == .completed)
        #expect(model.session?.driver.availability == .available)
        #expect(model.pendingSteps.count == 3)
    }

    @Test func stepNotAllowedFromTheRideOnScreenIsRefused() async throws {
        let updates = try await startRideThenGoOffline()
        defer { updates.cancel() }

        // The driver hasn't arrived, so the trip can't start.
        await model.startTrip(rideID: ride.id)

        #expect(model.pendingSteps.isEmpty)
        #expect(model.alert == .error(.actionNotAllowed))
        #expect(model.session?.activeRide?.status == .driverEnRoute)
    }

    @Test func queuedStepsReplayInOrderOnReconnecting() async throws {
        let updates = try await startRideThenGoOffline()
        defer { updates.cancel() }
        await model.markArrived(rideID: ride.id)
        await model.startTrip(rideID: ride.id)
        let beforeTap = Date.now
        await model.completeTrip(rideID: ride.id)
        let afterTap = Date.now

        await service.setConnected(true)
        await waitUntil { model.pendingSteps.isEmpty && model.isPerformingAction == false }

        let completed = try #require(await service.currentSession().pastRides.first)
        #expect(completed.id == ride.id)
        #expect(completed.status == .completed)
        // The trip ended when the driver tapped, not when the step reached the service.
        let endedAt = try #require(completed.endedAt)
        #expect(endedAt >= beforeTap && endedAt <= afterTap)
        #expect(model.session?.pastRides.first?.status == .completed)
        #expect(model.alert == nil)
    }

    @Test func rejectedStepDropsTheRestOfTheQueueAndSaysSo() async throws {
        let updates = try await startRideThenGoOffline()
        defer { updates.cancel() }
        await model.markArrived(rideID: ride.id)
        await model.startTrip(rideID: ride.id)
        await service.failNextRequest(with: .actionNotAllowed)

        await service.setConnected(true)
        await waitUntil { model.alert != nil }

        #expect(model.alert == .offlineStepsNotSent)
        #expect(model.pendingSteps.isEmpty)
        // The server wins: the ride shows as the service has it.
        #expect(model.session?.activeRide?.status == .driverEnRoute)
        #expect(await service.ride(id: ride.id)?.status == .driverEnRoute)
    }

    @Test func riderCancellingWhileOfflineShowsTheRidersCancellation() async throws {
        let updates = try await startRideThenGoOffline()
        defer { updates.cancel() }
        await model.markArrived(rideID: ride.id)
        try await service.simulateRideCancelled(id: ride.id)

        await service.setConnected(true)
        await waitUntil { model.pendingSteps.isEmpty && model.alert?.cancelledRideID == ride.id }

        #expect(model.session?.activeRide == nil)
    }

    /// Puts the driver on the fixture ride online, through a service that takes a second to respond, then loses the
    /// connection. The caller starts the model's updates.
    private func startRideThenGoOffline(
        on delayedService: MockRideService,
        model delayedModel: DriverModel
    ) async throws {
        await delayedService.addRide(ride)
        let goingOnline = Task { await delayedModel.goOnline() }
        await time.waitForSleeper()
        time.advance(by: 1)
        await goingOnline.value
        try await delayedService.offerRide(id: ride.id)
        await waitUntil { delayedModel.session?.pendingOffer != nil }
        let offerID = try #require(delayedModel.session?.pendingOffer?.id)
        let accepting = Task { await delayedModel.acceptOffer(id: offerID) }
        // The offer's expiry is also waiting.
        await time.waitForSleeper(count: 2)
        time.advance(by: 1)
        await accepting.value
        await delayedService.setConnected(false)
        await waitUntil { delayedModel.isOffline }
    }

    @Test func connectionLostDuringReplayKeepsTheQueue() async throws {
        let delayedService = MockRideService.forModelTests(time: time, responseDelay: 1)
        let delayedModel = DriverModel(service: delayedService)
        let updates = Task { await delayedModel.start() }
        defer { updates.cancel() }
        try await startRideThenGoOffline(on: delayedService, model: delayedModel)
        await delayedModel.markArrived(rideID: ride.id)

        await delayedService.setConnected(true)
        // The replayed step is on its way when the connection drops again.
        await time.waitForSleeper()
        await delayedService.setConnected(false)
        time.advance(by: 1)
        await waitUntil { delayedModel.isPerformingAction == false && delayedModel.isOffline }

        #expect(delayedModel.pendingSteps.map(\.event) == [.driverArrived])
        #expect(delayedModel.alert == nil)
    }

    @Test func dismissedRiderCancellationIsntFollowedByTheConflictMessage() async throws {
        let delayedService = MockRideService.forModelTests(time: time, responseDelay: 1)
        let delayedModel = DriverModel(service: delayedService)
        let updates = Task { await delayedModel.start() }
        defer { updates.cancel() }
        try await startRideThenGoOffline(on: delayedService, model: delayedModel)
        await delayedModel.markArrived(rideID: ride.id)
        try await delayedService.simulateRideCancelled(id: ride.id)

        await delayedService.setConnected(true)
        await waitUntil { delayedModel.alert?.cancelledRideID == ride.id }
        // The replayed step is on its way when the driver dismisses the rider's cancellation.
        await time.waitForSleeper()
        delayedModel.alert = nil
        time.advance(by: 1)
        await waitUntil { delayedModel.pendingSteps.isEmpty }

        // The cancellation already explained why the step couldn't be sent.
        #expect(delayedModel.alert == nil)
    }

    @Test func stepTheServiceAlreadyConfirmedDoesntHideLaterSteps() async throws {
        let updates = try await startRideThenGoOffline()
        defer { updates.cancel() }
        await model.markArrived(rideID: ride.id)
        await model.startTrip(rideID: ride.id)
        var arrived = try #require(model.session?.pastRides.isEmpty == true ? ride : nil)
        try arrived.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try arrived.apply(.driverArrived)
        let received = try #require(model.session)

        // During replay, the service's session for the first step can arrive before it leaves the queue.
        model.apply(
            DriverSession(
                version: received.version + 1,
                driver: received.driver,
                pendingOffer: nil,
                activeRide: arrived,
                pastRides: received.pastRides,
                waitingRides: received.waitingRides
            )
        )

        #expect(model.session?.activeRide?.status == .inProgress)
    }
}
