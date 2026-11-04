import Foundation
import Testing
@testable import Fareline

/// Covers past rides surviving a relaunch. A class, so that `deinit` can remove each test's folder.
final class MockRideServiceHistoryTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()
    private let folder = URL.temporaryDirectory.appending(path: "MockRideServiceHistoryTests-\(UUID().uuidString)")
    private let pastRideStore: PastRideStore

    init() {
        pastRideStore = PastRideStore(fileURL: folder.appending(path: "PastRides.json"))
    }

    deinit {
        try? FileManager.default.removeItem(at: folder)
    }

    private func makeService() -> MockRideService {
        MockRideService(
            configuration: MockRideServiceConfiguration(offerDelay: nil, offerLifetime: 30, responseDelay: 0),
            timeSource: time,
            driver: Driver(id: TestFixtures.driverID, name: PersonNameComponents()),
            pastRideStore: pastRideStore
        )
    }

    /// Puts the driver on the fixture ride.
    private func startRide(on service: MockRideService) async throws {
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)
        let offer = try #require(await service.sessionUpdates().first { _ in true }?.pendingOffer)
        _ = try await service.acceptOffer(id: offer.id)
    }

    @Test func serviceStartsWithSavedRides() async throws {
        let saved = [try TestFixtures.cancelledRide()]
        try pastRideStore.save(saved)

        let session = await makeService().sessionUpdates().first { _ in true }

        #expect(session?.pastRides == saved)
    }

    @Test func completedRideIsSaved() async throws {
        let service = makeService()
        try await startRide(on: service)
        _ = try await service.markArrived(rideID: ride.id)
        _ = try await service.startTrip(rideID: ride.id)

        let session = try await service.completeTrip(rideID: ride.id, at: time.now)

        #expect(pastRideStore.load() == session.pastRides)
        #expect(pastRideStore.load().first?.status == .completed)
    }

    @Test func cancelledRideIsSaved() async throws {
        let service = makeService()
        try await startRide(on: service)

        try await service.simulateRideCancelled(id: ride.id)

        #expect(pastRideStore.load().map(\.id) == [ride.id])
        #expect(pastRideStore.load().first?.status == .cancelled)
    }

    @Test func rideTheDriverCancelledIsSaved() async throws {
        let service = makeService()
        try await startRide(on: service)

        _ = try await service.cancelRide(rideID: ride.id, at: time.now)

        #expect(pastRideStore.load().map(\.id) == [ride.id])
        #expect(pastRideStore.load().first?.cancelledBy == .driver)
    }

    @Test @MainActor func savedCancelledRideDoesntShowAnAlertOnLaunch() async throws {
        try pastRideStore.save([try TestFixtures.cancelledRide()])
        let model = DriverModel(service: makeService())
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        await waitUntil { model.session != nil }

        #expect(model.session?.pastRides.count == 1)
        #expect(model.alert == nil)
    }
}
