import Foundation
import Testing
@testable import Fareline

@Suite(.timeLimit(.minutes(1)))
struct MockRideServiceTests {
    static let offerLifetime: TimeInterval = 30

    private let time = ManualTimeSource()
    private let service: MockRideService
    private let ride = TestFixtures.ride()

    init() {
        service = Self.makeService(time: time, offerDelay: nil)
    }

    static func makeService(time: any TimeSource, offerDelay: TimeInterval?) -> MockRideService {
        MockRideService(
            configuration: MockRideServiceConfiguration(
                offerDelay: offerDelay,
                offerLifetime: offerLifetime,
                responseDelay: 0
            ),
            timeSource: time,
            driver: Driver(
                id: TestFixtures.driverID,
                name: PersonNameComponents(givenName: "Grace", familyName: "Hopper")
            )
        )
    }

    /// Puts the driver online with a pending offer for the fixture ride.
    private func makeOffer() async throws -> RideOffer {
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)
        return try #require(await service.currentSession().pendingOffer)
    }

    /// Puts the driver on the fixture ride.
    private func startRide() async throws {
        let offer = try await makeOffer()
        _ = try await service.acceptOffer(id: offer.id)
    }

    /// Waits for an update that happens on the service's own timers.
    private func waitForSession(where condition: (DriverSession) -> Bool) async -> DriverSession? {
        for await session in await service.sessionUpdates() where condition(session) {
            return session
        }
        return nil
    }

    @Test func demoDriverKeepsTheSameIDAcrossLaunches() {
        // Saved rides record their driver, so a new ID on each launch would orphan them.
        #expect(MockRideData.driver.id.uuidString == "00000000-0000-0000-0000-000000000001")
    }

    // MARK: - Availability

    @Test func newSubscriberReceivesTheCurrentSession() async throws {
        let session = try await service.currentSession()

        #expect(session.driver.availability == .offline)
        #expect(session.pendingOffer == nil)
        #expect(session.activeRide == nil)
    }

    @Test func eachChangeIncreasesTheVersion() async throws {
        let online = try await service.goOnline()
        let offline = try await service.goOffline()

        #expect(online.version < offline.version)
    }

    @Test func driverOnARideCantGoOffline() async throws {
        try await startRide()

        await #expect(throws: RideServiceError.actionNotAllowed) {
            try await service.goOffline()
        }
        #expect(try await service.currentSession().driver.availability == .onRide)
    }

    @Test func goingOfflineWithdrawsThePendingOffer() async throws {
        _ = try await makeOffer()

        let session = try await service.goOffline()

        #expect(session.pendingOffer == nil)
    }

    // MARK: - Creating offers

    @Test func availableDriverReceivesAnOfferAfterTheDelay() async throws {
        let service = Self.makeService(time: time, offerDelay: 5)
        _ = try await service.goOnline()

        time.advance(by: 5)

        var offer: RideOffer?
        for await session in await service.sessionUpdates() where session.pendingOffer != nil {
            offer = session.pendingOffer
            break
        }
        #expect(offer?.ride.status == .awaitingDriver)
    }

    @Test func rideCantHaveASecondPendingOffer() async throws {
        let offer = try await makeOffer()

        await #expect(throws: RideServiceError.actionNotAllowed) {
            try await service.offerRide(id: ride.id)
        }
        #expect(try await service.currentSession().pendingOffer?.id == offer.id)
    }

    @Test func onlyRidesAwaitingADriverCanBeOffered() async throws {
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.simulateRideTaken(id: ride.id, byDriverID: UUID(testValue: 9))

        await #expect(throws: RideServiceError.actionNotAllowed) {
            try await service.offerRide(id: ride.id)
        }
    }

    @Test func offlineDriverCantBeOfferedARide() async {
        await service.addRide(ride)

        await #expect(throws: RideServiceError.actionNotAllowed) {
            try await service.offerRide(id: ride.id)
        }
    }

    // MARK: - Responding to offers

    @Test func acceptingUpdatesTheOfferRideAndDriverTogether() async throws {
        let offer = try await makeOffer()

        let session = try await service.acceptOffer(id: offer.id)

        #expect(session.pendingOffer == nil)
        #expect(session.activeRide?.status == .driverEnRoute)
        #expect(session.activeRide?.driverID == TestFixtures.driverID)
        #expect(session.driver.availability == .onRide)
    }

    @Test func decliningLeavesTheRideAwaitingADriver() async throws {
        let offer = try await makeOffer()

        let session = try await service.declineOffer(id: offer.id)

        #expect(session.pendingOffer == nil)
        #expect(session.driver.availability == .available)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }

    @Test func offerExpiresIfIgnored() async throws {
        _ = try await makeOffer()

        time.advance(by: Self.offerLifetime)
        let session = await waitForSession { $0.pendingOffer == nil }

        #expect(session?.driver.availability == .available)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }

    /// If the expiry timer gave up after waking early, the offer would stay pending and this test would time out.
    @Test func offerStillExpiresIfTheTimerWakesEarly() async throws {
        let service = Self.makeService(time: EarlyWakingTimeSource(base: time), offerDelay: nil)
        await service.addRide(ride)
        _ = try await service.goOnline()
        try await service.offerRide(id: ride.id)

        await time.waitForSleeper()
        time.advance(by: Self.offerLifetime)

        for await session in await service.sessionUpdates() where session.pendingOffer == nil {
            break
        }
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }

    @Test func acceptingAtTheExpiryTimeFails() async throws {
        let offer = try await makeOffer()

        time.advance(by: Self.offerLifetime)

        await #expect(throws: RideServiceError.offerNoLongerAvailable) {
            try await service.acceptOffer(id: offer.id)
        }

        // The offer ends right away, rather than staying on screen until the timer runs.
        let session = try await service.currentSession()
        #expect(session.pendingOffer == nil)
        #expect(session.driver.availability == .available)
    }

    @Test func decliningAnOfferThatAlreadyEndedSucceeds() async throws {
        let offer = try await makeOffer()

        time.advance(by: Self.offerLifetime)
        let session = try await service.declineOffer(id: offer.id)

        #expect(session.pendingOffer == nil)
        #expect(session.driver.availability == .available)
    }

    @Test func acceptingFailsIfTheRideWasCancelled() async throws {
        let offer = try await makeOffer()
        try await service.simulateRideCancelled(id: ride.id)

        await #expect(throws: RideServiceError.offerNoLongerAvailable) {
            try await service.acceptOffer(id: offer.id)
        }

        let session = try await service.currentSession()
        #expect(session.activeRide == nil)
        #expect(session.driver.availability == .available)
        #expect(session.pastRides.isEmpty)
        #expect(await service.ride(id: ride.id)?.status == .cancelled)
    }

    @Test func acceptingFailsIfAnotherDriverTookTheRide() async throws {
        let otherDriverID = UUID(testValue: 9)
        let offer = try await makeOffer()
        try await service.simulateRideTaken(id: ride.id, byDriverID: otherDriverID)

        await #expect(throws: RideServiceError.offerNoLongerAvailable) {
            try await service.acceptOffer(id: offer.id)
        }

        #expect(try await service.currentSession().driver.availability == .available)
        #expect(await service.ride(id: ride.id)?.driverID == otherDriverID)
    }

    // MARK: - Simulated failures

    @Test func simulatedFailureChangesNothingAndCanBeRetried() async throws {
        await service.failNextRequest(with: .networkUnavailable)

        await #expect(throws: RideServiceError.networkUnavailable) {
            try await service.goOnline()
        }
        #expect(try await service.currentSession().driver.availability == .offline)

        let session = try await service.goOnline()
        #expect(session.driver.availability == .available)
    }
}
