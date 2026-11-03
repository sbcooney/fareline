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

    @Test func cancellingRecordsWhenTheRideEnded() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))

        try ride.apply(.cancelled(date: TestFixtures.date))

        #expect(ride.status == .cancelled)
        #expect(ride.endedAt == TestFixtures.date)
    }

    @Test func rejectedCancellationLeavesTheEndTimeUnchanged() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try ride.apply(.driverArrived)
        try ride.apply(.tripStarted)
        try ride.apply(.tripCompleted(date: TestFixtures.date))
        let lateCancellation = RideEvent.cancelled(date: TestFixtures.date.addingTimeInterval(60))

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
