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
        model.apply(try await currentSession())
        await model.acceptOffer(id: try #require(model.session?.pendingOffer?.id))
    }

    private func currentSession() async throws -> DriverSession {
        for await session in await service.sessionUpdates() {
            return session
        }
        throw CancellationError()
    }

    @Test func riderCancellationReplacesAnError() async throws {
        try await startRide()
        await service.failNextRequest(with: .networkUnavailable)
        await model.markArrived(rideID: ride.id)
        try #require(model.alert == .error(.networkUnavailable))

        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await currentSession())

        #expect(model.alert?.cancelledRideID == ride.id)
    }

    @Test func errorDoesntReplaceARiderCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await currentSession())
        await service.failNextRequest(with: .networkUnavailable)

        await model.goOffline()

        #expect(model.alert?.cancelledRideID == ride.id)
    }

    @Test func stepFailingAfterTheCancellationWasDismissedShowsNoError() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await currentSession())
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
        model.apply(try await currentSession())

        #expect(model.alert == nil)
    }

    @Test func newOfferKeepsARiderCancellation() async throws {
        try await startRide()
        try await service.simulateRideCancelled(id: ride.id)
        model.apply(try await currentSession())

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
        model.apply(try await currentSession())

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
