import Foundation
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
        model.apply(try await service.currentSession())
        await model.acceptOffer(id: try #require(model.session?.pendingOffer?.id))
        try #require(model.session?.activeRide?.id == ride.id)
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
        #expect(model.alert == nil)
    }

    @Test func pastRideIsFoundByIDAfterNewerRidesEnd() async throws {
        try await startRide()
        await model.markArrived(rideID: ride.id)
        await model.startTrip(rideID: ride.id)
        await model.completeTrip(rideID: ride.id)

        let newerRide = Ride(
            id: UUID(testValue: 12),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        await service.addRide(newerRide)
        try await service.offerRide(id: newerRide.id)
        model.apply(try await service.currentSession())
        await model.acceptOffer(id: try #require(model.session?.pendingOffer?.id))
        try await service.simulateRideCancelled(id: newerRide.id)
        model.apply(try await service.currentSession())

        #expect(model.session?.pastRides.map(\.id) == [newerRide.id, ride.id])
        #expect(model.pastRide(id: ride.id)?.status == .completed)
        #expect(model.pastRide(id: newerRide.id)?.status == .cancelled)
    }

    @Test func unknownPastRideIsntFound() async throws {
        try await startRide()

        #expect(model.pastRide(id: ride.id) == nil)
        #expect(model.pastRide(id: UUID(testValue: 13)) == nil)
    }

    @Test func failedStepKeepsTheRideAndCanBeRetried() async throws {
        try await startRide()
        await service.failNextRequest(with: .networkUnavailable)

        await model.markArrived(rideID: ride.id)
        #expect(model.alert == .error(.networkUnavailable))
        #expect(model.session?.activeRide?.status == .driverEnRoute)

        await model.markArrived(rideID: ride.id)
        #expect(model.alert == nil)
        #expect(model.session?.activeRide?.status == .driverArrived)
    }

    @Test func riderCancellingIsShownToTheDriver() async throws {
        try await startRide()
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        try await service.simulateRideCancelled(id: ride.id)
        await waitUntil { model.alert != nil }

        #expect(model.alert?.cancelledRideID == ride.id)
        #expect(model.session?.activeRide == nil)
        #expect(model.session?.driver.availability == .available)
    }

    @Test func cancellationIsShownEvenIfTheModelNeverSawTheRideActive() async throws {
        await service.addRide(ride)
        await model.goOnline()
        try await service.offerRide(id: ride.id)
        model.apply(try await service.currentSession())
        let offer = try #require(model.session?.pendingOffer)
        _ = try await service.acceptOffer(id: offer.id)
        try await service.simulateRideCancelled(id: ride.id)

        model.apply(try await service.currentSession())

        #expect(model.alert?.cancelledRideID == ride.id)
    }

    @Test func pastRidesInTheFirstSessionArentReportedAsCancellations() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        let newModel = DriverModel(service: service)

        newModel.apply(try await service.currentSession())

        #expect(newModel.alert == nil)
    }

    @Test func stepTappedAfterTheRiderCancelledShowsOnlyTheCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await service.currentSession())

        await model.markArrived(rideID: ride.id)

        #expect(model.alert?.cancelledRideID == ride.id)
    }

    @Test func stepThatFailedBeforeTheCancellationArrivedShowsOnlyTheCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        await model.markArrived(rideID: ride.id)
        #expect(model.alert == .error(.rideNoLongerAvailable))

        model.apply(try await service.currentSession())

        #expect(model.alert?.cancelledRideID == ride.id)
    }
}
