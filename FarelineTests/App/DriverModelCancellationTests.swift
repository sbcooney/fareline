import Foundation
import Testing
@testable import Fareline

/// Covers the driver cancelling their ride, and what they're shown when the rider cancels at the same time.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelCancellationTests {
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
        model.apply(try await service.currentSession())
        await model.acceptOffer(id: try #require(model.session?.pendingOffer?.id))
        try #require(model.session?.activeRide?.id == ride.id)
    }

    @Test func driverCancellingEndsTheRideWithoutAnAlert() async throws {
        try await startRide()
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        await model.cancelRide(rideID: ride.id)

        #expect(model.session?.activeRide == nil)
        #expect(model.session?.driver.availability == .available)
        #expect(model.session?.pastRides.first?.cancelledBy == .driver)
        // The driver chose this, so the rider-cancelled alert would be wrong.
        #expect(model.alert == nil)
    }

    @Test func riderCancellingFirstShowsOnlyTheRidersCancellation() async throws {
        try await startRide()
        let updates = Task { await model.start() }
        defer { updates.cancel() }
        try await service.simulateRideCancelled(id: ride.id)
        await waitUntil { model.alert != nil }

        await model.cancelRide(rideID: ride.id)

        #expect(model.alert?.cancelledRideID == ride.id)
        #expect(model.session?.pastRides.first?.cancelledBy == .rider)
    }

    @Test func driverCancellationThatFailedBecauseTheRiderCancelledShowsOnlyTheRidersCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        // The model hasn't seen the rider's cancellation, so the driver's request fails with no explanation yet.
        await model.cancelRide(rideID: ride.id)
        #expect(model.alert == .error(.rideNoLongerAvailable))

        model.apply(try await service.currentSession())

        #expect(model.alert?.cancelledRideID == ride.id)
    }

    @Test func stepForARideTheDriverCancelledShowsTheError() async throws {
        try await startRide()
        await model.cancelRide(rideID: ride.id)

        await model.markArrived(rideID: ride.id)

        // No rider cancellation explains the failure, so the driver sees it.
        #expect(model.alert == .error(.rideNoLongerAvailable))
    }
}
