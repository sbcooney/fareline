import Foundation
import Testing
@testable import Fareline

/// Covers which passed-over rides the waiting list shows, and in what order.
struct WaitingListTests {
    private var list = WaitingList()

    private func ride(_ testValue: UInt8, requestedAt offset: TimeInterval) -> Ride {
        Ride(
            id: UUID(testValue: testValue),
            rider: Rider(id: UUID(testValue: testValue + 100), name: PersonNameComponents()),
            pickup: Place(name: "Union Station", address: "50 Massachusetts Ave NE"),
            dropoff: Place(name: "National Mall", address: "900 Ohio Dr SW"),
            fare: Fare(amount: 10, currencyCode: "USD"),
            requestedAt: TestFixtures.date.addingTimeInterval(offset)
        )
    }

    @Test mutating func listsLongestWaitFirst() {
        let newer = ride(1, requestedAt: 60)
        let older = ride(2, requestedAt: 0)
        list.add(newer.id)
        list.add(older.id)

        let rides = list.rides(in: [newer.id: newer, older.id: older])

        #expect(rides.map(\.id) == [older.id, newer.id])
    }

    @Test mutating func ridesRequestedTogetherAreOrderedByID() {
        let second = ride(2, requestedAt: 0)
        let first = ride(1, requestedAt: 0)
        list.add(second.id)
        list.add(first.id)

        let rides = list.rides(in: [first.id: first, second.id: second])

        #expect(rides.map(\.id) == [first.id, second.id])
    }

    @Test mutating func leavesOutRidesThatNoLongerNeedADriver() throws {
        var taken = ride(1, requestedAt: 0)
        try taken.apply(.driverAssigned(driverID: TestFixtures.driverID))
        let waiting = ride(2, requestedAt: 0)
        list.add(taken.id)
        list.add(waiting.id)

        let rides = list.rides(in: [taken.id: taken, waiting.id: waiting])

        #expect(rides.map(\.id) == [waiting.id])
        // A taken ride stays recorded, so it's never offered again.
        #expect(list.hasListed(taken.id))
    }

    @Test mutating func leavesOutRidesThatWerentPassedOver() {
        let listed = ride(1, requestedAt: 0)
        let offered = ride(2, requestedAt: 0)
        list.add(listed.id)

        let rides = list.rides(in: [listed.id: listed, offered.id: offered])

        #expect(rides.map(\.id) == [listed.id])
        #expect(list.hasListed(offered.id) == false)
    }
}
