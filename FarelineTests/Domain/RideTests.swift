import Foundation
import Testing
@testable import Fareline

struct RideTests {
    @Test func newRideAwaitsADriver() {
        let ride = TestFixtures.ride()

        #expect(ride.status == .awaitingDriver)
        #expect(ride.driverID == nil)
        #expect(ride.completedAt == nil)
    }

    @Test func assigningADriverRecordsTheDriver() throws {
        var ride = TestFixtures.ride()

        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))

        #expect(ride.status == .driverEnRoute)
        #expect(ride.driverID == TestFixtures.driverID)
    }

    @Test func completingATripRecordsTheCompletionTime() throws {
        var ride = TestFixtures.ride()

        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try ride.apply(.driverArrived)
        try ride.apply(.tripStarted)
        try ride.apply(.tripCompleted(date: TestFixtures.date))

        #expect(ride.status == .completed)
        #expect(ride.completedAt == TestFixtures.date)
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

    @Test func rideSurvivesEncoding() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))

        let data = try JSONEncoder().encode(ride)
        let decoded = try JSONDecoder().decode(Ride.self, from: data)

        #expect(decoded == ride)
    }
}
