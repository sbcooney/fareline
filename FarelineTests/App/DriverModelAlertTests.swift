import Foundation
import Testing
@testable import Fareline

/// Covers which alert the driver sees when more than one explanation is due.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelAlertTests {
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
    }

    @Test func riderCancellationReplacesAnError() async throws {
        try await startRide()
        await service.failNextRequest(with: .networkUnavailable)
        await model.markArrived(rideID: ride.id)
        try #require(model.alert == .error(.networkUnavailable))

        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await service.currentSession())

        #expect(model.alert?.cancelledRideID == ride.id)
    }

    @Test func errorDoesntReplaceARiderCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await service.currentSession())
        await service.failNextRequest(with: .networkUnavailable)

        await model.goOffline()

        #expect(model.alert?.cancelledRideID == ride.id)
    }

    @Test func stepFailingAfterTheCancellationWasDismissedShowsNoError() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await service.currentSession())
        model.alert = nil

        await model.markArrived(rideID: ride.id)

        #expect(model.alert == nil)
    }

    @Test func newOfferClearsAnError() async throws {
        await model.goOnline()
        await model.acceptOffer(id: UUID(testValue: 20))
        try #require(model.alert == .error(.offerNoLongerAvailable))

        await service.addRide(ride)
        try await service.offerRide(id: ride.id)
        model.apply(try await service.currentSession())

        #expect(model.alert == nil)
    }

    @Test func errorFromBeforeANewOfferArrivedIsDropped() async throws {
        let service = MockRideService.forModelTests(time: time, responseDelay: 1)
        let model = DriverModel(service: service)
        let updates = Task { await model.start() }
        defer { updates.cancel() }
        await service.addRide(ride)
        let goingOnline = Task { await model.goOnline() }
        await time.waitForSleeper()
        time.advance(by: 1)
        await goingOnline.value
        try await service.offerRide(id: ride.id)
        await waitUntil { model.session?.pendingOffer != nil }
        let firstOfferID = try #require(model.session?.pendingOffer?.id)

        // The accept is in flight while the first offer is withdrawn and a new one arrives.
        let accepting = Task { await model.acceptOffer(id: firstOfferID) }
        await time.waitForSleeper(count: 2)
        try await service.simulateRideCancelled(id: ride.id)
        let nextRide = Ride(
            id: UUID(testValue: 22),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        await service.addRide(nextRide)
        try await service.offerRide(id: nextRide.id)
        await waitUntil { model.session?.pendingOffer?.ride.id == nextRide.id }
        time.advance(by: 1)
        await accepting.value

        #expect(model.alert == nil)
    }

    @Test func newOfferKeepsARiderCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await service.currentSession())

        let nextRide = Ride(
            id: UUID(testValue: 21),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        await service.addRide(nextRide)
        try await service.offerRide(id: nextRide.id)
        model.apply(try await service.currentSession())

        #expect(model.alert?.cancelledRideID == ride.id)
    }

    @Test func dismissingClearsTheAlert() async {
        await service.failNextRequest(with: .networkUnavailable)
        await model.goOnline()
        #expect(model.alert == .error(.networkUnavailable))

        model.alert = nil

        #expect(model.alert == nil)
    }
}
