import Foundation
import Testing
@testable import Fareline

/// Covers what the model does when the connection drops and returns.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelOfflineTests {
    private let time = ManualTimeSource()
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
}
