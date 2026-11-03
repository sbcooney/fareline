import Foundation
import Testing
@testable import Fareline

struct RideCodingTests {
    /// Every state a ride can reach, each built through the domain's own rules.
    static let states: [Ride] = {
        let assigned = RideEvent.driverAssigned(driverID: TestFixtures.driverID)
        let paths: [[RideEvent]] = [
            [],
            [assigned],
            [assigned, .driverArrived],
            [assigned, .driverArrived, .tripStarted],
            [assigned, .driverArrived, .tripStarted, .tripCompleted(date: TestFixtures.date)],
            [assigned, .cancelled(by: .rider, date: TestFixtures.date)],
            [assigned, .cancelled(by: .driver, date: TestFixtures.date)],
            [assigned, .driverArrived, .tripStarted, .cancelled(by: .driver, date: TestFixtures.date)],
            [.cancelled(by: .rider, date: TestFixtures.date)]
        ]
        return paths.map { events in
            var ride = TestFixtures.ride()
            for event in events {
                try? ride.apply(event)
            }
            return ride
        }
    }()

    /// `states` builds each ride with `try?`, so this catches a path that silently stopped short.
    @Test func statesCoverEveryStatus() {
        #expect(Set(Self.states.map(\.status)) == Set(RideStatus.allCases))
    }

    @Test(arguments: states)
    func everyStateRoundTrips(ride: Ride) throws {
        let data = try JSONEncoder().encode(ride)

        #expect(try JSONDecoder().decode(Ride.self, from: data) == ride)
    }

    @Test func completedRideWithNoEndTimeIsRejected() throws {
        let data = try savedJSON(of: TestFixtures.completedRide()) { $0["endedAt"] = nil }

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Ride.self, from: data)
        }
    }

    @Test func unfinishedRideWithAnEndTimeIsRejected() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        // `JSONEncoder` saves dates as seconds since the reference date by default.
        let data = try savedJSON(of: ride) { $0["endedAt"] = TestFixtures.date.timeIntervalSinceReferenceDate }

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Ride.self, from: data)
        }
    }

    @Test func rideWaitingForADriverWithADriverIsRejected() throws {
        let data = try savedJSON(of: TestFixtures.ride()) { $0["driverID"] = TestFixtures.driverID.uuidString }

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Ride.self, from: data)
        }
    }

    @Test func completedRideWithNoDriverIsRejected() throws {
        let data = try savedJSON(of: TestFixtures.completedRide()) { $0["driverID"] = nil }

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Ride.self, from: data)
        }
    }

    @Test func cancelledRideSavedWithoutACancellerWasCancelledByTheRider() throws {
        // Rides saved before cancellations recorded who cancelled were all cancelled by riders.
        let data = try savedJSON(of: TestFixtures.cancelledRide()) { $0["cancelledBy"] = nil }

        #expect(try JSONDecoder().decode(Ride.self, from: data).cancelledBy == .rider)
    }

    @Test func rideCancelledByADriverWithNoDriverIsRejected() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try ride.apply(.cancelled(by: .driver, date: TestFixtures.date))
        let data = try savedJSON(of: ride) { $0["driverID"] = nil }

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Ride.self, from: data)
        }
    }

    @Test func completedRideWithACancellerIsRejected() throws {
        let data = try savedJSON(of: TestFixtures.completedRide()) { $0["cancelledBy"] = "driver" }

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Ride.self, from: data)
        }
    }

    /// Encodes a ride, then changes the saved fields to make state the domain doesn't allow.
    private func savedJSON(of ride: Ride, changing change: (inout [String: Any]) -> Void) throws -> Data {
        let data = try JSONEncoder().encode(ride)
        var object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        change(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }
}
