import Foundation
import Testing
@testable import Fareline

struct RideTests {
    @Test func newRideAwaitsADriver() {
        let ride = TestFixtures.ride()

        #expect(ride.status == .awaitingDriver)
        #expect(ride.driverID == nil)
        #expect(ride.endedAt == nil)
    }

    @Test func assigningADriverRecordsTheDriver() throws {
        var ride = TestFixtures.ride()

        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))

        #expect(ride.status == .driverEnRoute)
        #expect(ride.driverID == TestFixtures.driverID)
    }

    @Test func completingATripRecordsWhenItEnded() throws {
        var ride = TestFixtures.ride()

        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try ride.apply(.driverArrived)
        try ride.apply(.tripStarted)
        try ride.apply(.tripCompleted(date: TestFixtures.date))

        #expect(ride.status == .completed)
        #expect(ride.endedAt == TestFixtures.date)
    }

    @Test(arguments: [RideRole.rider, .driver])
    func cancellingRecordsWhoCancelledAndWhen(role: RideRole) throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))

        try ride.apply(.cancelled(by: role, date: TestFixtures.date))

        #expect(ride.status == .cancelled)
        #expect(ride.cancelledBy == role)
        #expect(ride.endedAt == TestFixtures.date)
    }

    @Test func driverCanCancelDuringTheTrip() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try ride.apply(.driverArrived)
        try ride.apply(.tripStarted)

        try ride.apply(.cancelled(by: .driver, date: TestFixtures.date))

        #expect(ride.status == .cancelled)
        #expect(ride.cancelledBy == .driver)
    }

    @Test func riderCantCancelDuringTheTrip() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try ride.apply(.driverArrived)
        try ride.apply(.tripStarted)
        let original = ride
        let cancellation = RideEvent.cancelled(by: .rider, date: TestFixtures.date)

        #expect(throws: RideTransitionError(status: .inProgress, event: cancellation)) {
            try ride.apply(cancellation)
        }
        #expect(ride == original)
    }

    @Test func completedRideRecordsNoCanceller() throws {
        #expect(try TestFixtures.completedRide().cancelledBy == nil)
    }

    @Test func rejectedCancellationLeavesTheEndTimeUnchanged() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try ride.apply(.driverArrived)
        try ride.apply(.tripStarted)
        try ride.apply(.tripCompleted(date: TestFixtures.date))
        let lateCancellation = RideEvent.cancelled(by: .driver, date: TestFixtures.date.addingTimeInterval(60))

        #expect(throws: RideTransitionError(status: .completed, event: lateCancellation)) {
            try ride.apply(lateCancellation)
        }
        #expect(ride.endedAt == TestFixtures.date)
    }

    @Test func invalidEventLeavesTheRideUnchanged() {
        var ride = TestFixtures.ride()
        let original = ride
        let event = RideEvent.tripCompleted(date: TestFixtures.date)

        #expect(throws: RideTransitionError(status: .awaitingDriver, event: event)) {
            try ride.apply(event)
        }
        #expect(ride == original)
    }

    @Test func secondDriverCantTakeAnAssignedRide() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        let otherDriver = RideEvent.driverAssigned(driverID: UUID())

        #expect(throws: RideTransitionError(status: .driverEnRoute, event: otherDriver)) {
            try ride.apply(otherDriver)
        }
        #expect(ride.driverID == TestFixtures.driverID)
    }
}
