import Foundation
import Testing
@testable import Fareline

struct PastRideFilterTests {
    /// A completed ride, one the rider cancelled, and one the driver cancelled, newest first.
    private let rides: [Ride]

    init() throws {
        let completed = try TestFixtures.completedRide()

        var riderCancelled = Self.ride(id: 60)
        try riderCancelled.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try riderCancelled.apply(.cancelled(by: .rider, date: TestFixtures.date))

        var driverCancelled = Self.ride(id: 61)
        try driverCancelled.apply(.driverAssigned(driverID: TestFixtures.driverID))
        try driverCancelled.apply(.cancelled(by: .driver, date: TestFixtures.date))

        rides = [riderCancelled, completed, driverCancelled]
    }

    /// Returns a copy of the fixture ride with another ID.
    private static func ride(id: UInt8) -> Ride {
        let ride = TestFixtures.ride()
        return Ride(
            id: UUID(testValue: id),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: ride.requestedAt
        )
    }

    @Test func allRidesMatchesEveryRideInOrder() {
        #expect(rides.filter(PastRideFilter.all.matches) == rides)
    }

    @Test func completedMatchesOnlyCompletedRides() {
        #expect(rides.filter(PastRideFilter.completed.matches).map(\.status) == [.completed])
    }

    @Test func cancelledMatchesRidesEitherPartyCancelled() {
        let cancelled = rides.filter(PastRideFilter.cancelled.matches)

        // Both cancellations, in the order they were given.
        #expect(cancelled.map(\.id) == [rides[0].id, rides[2].id])
    }

    @Test(arguments: [
        (PastRideFilter.all, "All Rides"),
        (.completed, "Completed"),
        (.cancelled, "Cancelled")
    ])
    func titleNamesTheChoice(filter: PastRideFilter, expected: String) {
        #expect(String(localized: filter.title) == expected)
    }

    @Test(arguments: [
        (PastRideFilter.completed, "No Completed Rides"),
        (.cancelled, "No Cancelled Rides")
    ])
    func noMatchTitleNamesWhatsMissing(filter: PastRideFilter, expected: String) {
        #expect(String(localized: filter.noMatchTitle) == expected)
    }

    @Test(arguments: [
        (1, 1, "1 of 1 ride"),
        (1, 8, "1 of 8 rides"),
        (3, 8, "3 of 8 rides"),
        (0, 2, "0 of 2 rides")
    ])
    func countReadsAsShownOfTotal(shown: Int, total: Int, expected: String) {
        #expect(String(localized: PastRideFilter.countDescription(showing: shown, of: total)) == expected)
    }

    @Test(arguments: [
        (PastRideFilter.all, 0, "No past rides"),
        (.all, 1, "Showing 1 ride"),
        (.all, 5, "Showing all 5 rides"),
        (.completed, 1, "Showing 1 completed ride"),
        (.completed, 3, "Showing 3 completed rides"),
        (.completed, 0, "No completed rides"),
        (.cancelled, 1, "Showing 1 cancelled ride"),
        (.cancelled, 2, "Showing 2 cancelled rides"),
        (.cancelled, 0, "No cancelled rides")
    ])
    func announcementSaysWhatsShowing(filter: PastRideFilter, count: Int, expected: String) {
        #expect(String(localized: filter.announcement(showing: count)) == expected)
    }
}
