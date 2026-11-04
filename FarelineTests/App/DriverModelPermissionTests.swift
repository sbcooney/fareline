import Foundation
import Testing
@testable import Fareline

/// Covers what the model says the driver can do now, which views use to enable their controls.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelPermissionTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()
    private let service: MockRideService
    private let model: DriverModel

    init() {
        service = .forModelTests(time: time, responseDelay: 1)
        model = DriverModel(service: service)
    }

    /// Lets a request's simulated response delay finish.
    private func finish(_ request: Task<Void, Never>) async {
        await time.waitForSleeper()
        time.advance(by: 1)
        await request.value
    }

    /// Starts a request, and returns once the model is waiting on it.
    private func startRequest() async -> Task<Void, Never> {
        let request = Task { await model.goOffline() }
        await waitUntil { model.isPerformingAction }
        return request
    }

    private func goOnlineWithAnOffer() async throws {
        await service.addRide(ride)
        await finish(Task { await model.goOnline() })
        try await service.offerRide(id: ride.id)
        model.apply(try await service.currentSession())
    }

    private func goOnlineOnARide() async throws {
        try await goOnlineWithAnOffer()
        let offerID = try #require(model.session?.pendingOffer?.id)
        let accepting = Task { await model.acceptOffer(id: offerID) }
        // The offer's expiry is also waiting.
        await time.waitForSleeper(count: 2)
        time.advance(by: 1)
        await accepting.value
        try #require(model.session?.activeRide?.id == ride.id)
    }

    // MARK: - Answering an offer

    @Test func offerCanBeAnsweredOnlyWhenThereIsOne() async throws {
        await finish(Task { await model.goOnline() })
        #expect(model.canAnswerOffer == false)

        try await goOnlineWithAnOffer()
        #expect(model.canAnswerOffer)
    }

    @Test func offerCantBeAnsweredDuringARequest() async throws {
        try await goOnlineWithAnOffer()

        let offerID = try #require(model.session?.pendingOffer?.id)
        let request = Task { await model.declineOffer(id: offerID) }
        await waitUntil { model.isPerformingAction }
        #expect(model.canAnswerOffer == false)

        // The offer's expiry is also waiting.
        await time.waitForSleeper(count: 2)
        time.advance(by: 1)
        await request.value
    }

    @Test func offerCantBeAnsweredWithoutAConnection() async throws {
        try await goOnlineWithAnOffer()
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        await service.setConnected(false)
        await waitUntil { model.isOffline }

        #expect(model.canAnswerOffer == false)
    }

    // MARK: - Claiming a ride

    @Test func rideCanBeClaimedOnlyWhenAvailable() async throws {
        let updates = Task { await model.start() }
        defer { updates.cancel() }
        await waitUntil { model.session != nil }
        #expect(model.canClaimRide == false)

        await finish(Task { await model.goOnline() })
        #expect(model.canClaimRide)
    }

    @Test func rideCantBeClaimedDuringARequest() async {
        await finish(Task { await model.goOnline() })

        let request = await startRequest()
        #expect(model.canClaimRide == false)

        await finish(request)
    }

    @Test func rideCantBeClaimedWithoutAConnection() async {
        await finish(Task { await model.goOnline() })
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        await service.setConnected(false)
        await waitUntil { model.isOffline }

        #expect(model.canClaimRide == false)
    }

    @Test func rideCantBeClaimedDuringARide() async throws {
        try await goOnlineOnARide()

        #expect(model.canClaimRide == false)
    }

    // MARK: - Ride steps

    @Test func rideStepCanBeTakenOnlyOnARide() async throws {
        await finish(Task { await model.goOnline() })
        #expect(model.canTakeRideStep == false)

        try await goOnlineOnARide()
        #expect(model.canTakeRideStep)
    }

    @Test func rideStepCantBeTakenDuringARequest() async throws {
        try await goOnlineOnARide()

        let request = Task { await model.markArrived(rideID: ride.id) }
        await waitUntil { model.isPerformingAction }
        #expect(model.canTakeRideStep == false)

        await finish(request)
    }

    @Test func rideStepCanBeTakenWithoutAConnection() async throws {
        try await goOnlineOnARide()
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        await service.setConnected(false)
        await waitUntil { model.isOffline }

        // Steps queue offline, so the driver can keep going.
        #expect(model.canTakeRideStep)
    }
}
