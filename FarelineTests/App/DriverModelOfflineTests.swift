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
}
