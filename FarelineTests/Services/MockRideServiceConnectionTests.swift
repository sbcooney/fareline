import Foundation
import Testing
@testable import Fareline

/// Covers the mock losing and regaining its connection, as a real network would.
@Suite(.timeLimit(.minutes(1)))
struct MockRideServiceConnectionTests {
    private let time = ManualTimeSource()
    private let service: MockRideService
    private let ride = TestFixtures.ride()

    init() {
        service = MockRideServiceTests.makeService(time: time, offerDelay: nil)
    }

    @Test func requestFailsWhileDisconnectedAndChangesNothing() async throws {
        await service.setConnected(false)

        await #expect(throws: RideServiceError.networkUnavailable) {
            try await service.goOnline()
        }

        await service.setConnected(true)
        #expect(try await service.currentSession().driver.availability == .offline)
    }

    @Test func reconnectingSendsTheLatestSessionToExistingSubscribers() async throws {
        await service.addRide(ride)
        _ = try await service.goOnline()
        // One subscription across the disconnection, as the model has.
        var sessions = await service.sessionUpdates().makeAsyncIterator()
        _ = await sessions.next()
        await service.setConnected(false)
        // The mock's world keeps running while the driver is disconnected.
        try await service.offerRide(id: ride.id)

        await service.setConnected(true)

        #expect(await sessions.next()?.pendingOffer?.ride.id == ride.id)
    }

    @Test func offerExpiresOnTimeWhileDisconnected() async throws {
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)
        await service.setConnected(false)

        time.advance(by: MockRideServiceTests.offerLifetime)
        await service.setConnected(true)

        for await session in await service.sessionUpdates() where session.pendingOffer == nil {
            #expect(session.waitingRides.map(\.id) == [ride.id])
            break
        }
    }

    @Test func connectionUpdatesSendTheCurrentStateThenEachChange() async {
        var updates = await service.connectionUpdates().makeAsyncIterator()

        #expect(await updates.next() == true)
        await service.setConnected(false)
        #expect(await updates.next() == false)
        await service.setConnected(true)
        #expect(await updates.next() == true)
    }

    @Test func settingTheSameStateSendsNoUpdate() async {
        var updates = await service.connectionUpdates().makeAsyncIterator()
        _ = await updates.next()

        await service.setConnected(true)
        await service.setConnected(false)

        // Only the change is sent, so the next value is the disconnection.
        #expect(await updates.next() == false)
    }
}
