import Foundation
import Testing
@testable import Fareline

/// Covers how ride steps queued offline show on the service's last session.
struct DriverSessionPendingStepsTests {
    private let ride = TestFixtures.ride()

    /// Returns a session whose driver is on the fixture ride, heading to the pickup.
    private func sessionOnARide() throws -> DriverSession {
        var activeRide = ride
        try activeRide.apply(.driverAssigned(driverID: TestFixtures.driverID))
        var driver = Driver(id: TestFixtures.driverID, name: PersonNameComponents())
        try driver.apply(.wentOnline)
        try driver.apply(.rideAssigned)
        return DriverSession(
            version: 7,
            driver: driver,
            pendingOffer: nil,
            activeRide: activeRide,
            pastRides: [],
            waitingRides: []
        )
    }

    private func step(_ event: RideEvent, rideID: Ride.ID? = nil) -> PendingRideStep {
        PendingRideStep(rideID: rideID ?? ride.id, event: event)
    }

    @Test func noStepsLeavesTheSessionAsItIs() throws {
        let session = try sessionOnARide()

        #expect(session.applying([]) == session)
    }

    @Test func stepsMoveTheRideOn() throws {
        let session = try sessionOnARide()

        let shown = session.applying([step(.driverArrived), step(.tripStarted)])

        #expect(shown.activeRide?.status == .inProgress)
        #expect(shown.version == session.version)
    }

    @Test func completingTheRideMovesItToPastRidesAndFreesTheDriver() throws {
        let session = try sessionOnARide()

        let shown = session.applying([
            step(.driverArrived),
            step(.tripStarted),
            step(.tripCompleted(date: TestFixtures.date))
        ])

        #expect(shown.activeRide == nil)
        #expect(shown.pastRides.first?.status == .completed)
        #expect(shown.pastRides.first?.endedAt == TestFixtures.date)
        #expect(shown.driver.availability == .available)
    }

    @Test func cancellingTheRideMovesItToPastRidesAndFreesTheDriver() throws {
        let session = try sessionOnARide()

        let shown = session.applying([step(.cancelled(by: .driver, date: TestFixtures.date))])

        #expect(shown.activeRide == nil)
        #expect(shown.pastRides.first?.cancelledBy == .driver)
        #expect(shown.driver.availability == .available)
    }

    @Test func stepTheServiceAlreadyConfirmedIsSkipped() throws {
        // During replay, the service's session can arrive with a step confirmed before it leaves the queue.
        let confirmed = try sessionOnARide().applying([step(.driverArrived)])

        let shown = confirmed.applying([step(.driverArrived), step(.tripStarted)])

        #expect(shown.activeRide?.status == .inProgress)
    }

    @Test func stepForAnotherRideIsSkipped() throws {
        let session = try sessionOnARide()

        let shown = session.applying([step(.driverArrived, rideID: UUID(testValue: 99))])

        #expect(shown == session)
    }

    @Test func sessionWithNoRideIsLeftAsItIs() throws {
        let onARide = try sessionOnARide()
        let session = DriverSession(
            version: onARide.version,
            driver: onARide.driver,
            pendingOffer: nil,
            activeRide: nil,
            pastRides: [],
            waitingRides: []
        )

        #expect(session.applying([step(.driverArrived)]) == session)
    }
}
