import Foundation
import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelAvailabilityTests {
    private let time = ManualTimeSource()

    /// Returns a model whose driver has accepted a ride and is on it.
    private func makeModelOnARide(service: MockRideService) async throws -> DriverModel {
        let ride = TestFixtures.ride()
        let model = DriverModel(service: service)
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)
        for await session in await service.sessionUpdates() {
            model.apply(session)
            break
        }
        await model.acceptOffer(id: try #require(model.session?.pendingOffer?.id))
        return model
    }

    /// Lets a request's simulated response delay finish.
    private func finish(_ request: Task<Void, Never>) async {
        await time.waitForSleeper()
        time.advance(by: 1)
        await request.value
    }

    @Test func failedChangeKeepsTheStatusAndShowsAnError() async {
        let service = MockRideService.forModelTests(time: time)
        let model = DriverModel(service: service)
        await model.goOnline()
        await service.failNextRequest(with: .networkUnavailable)

        await model.goOffline()

        #expect(model.session?.driver.availability == .available)
        #expect(model.alert != nil)
    }

    @Test func availabilityCantChangeBeforeTheFirstSession() {
        let model = DriverModel(service: MockRideService.forModelTests(time: time))

        #expect(model.canChangeAvailability == false)
    }

    @Test func availabilityCantChangeWhileARequestIsInProgress() async {
        let model = DriverModel(service: MockRideService.forModelTests(time: time, responseDelay: 1))
        await finish(Task { await model.goOnline() })
        #expect(model.canChangeAvailability)

        let request = Task { await model.goOffline() }
        await waitUntil { model.isPerformingAction }
        #expect(model.canChangeAvailability == false)

        await finish(request)
        #expect(model.canChangeAvailability)
    }

    @Test func availabilityCantChangeDuringARide() async throws {
        let model = try await makeModelOnARide(service: .forModelTests(time: time))

        #expect(model.canChangeAvailability == false)
    }
}
