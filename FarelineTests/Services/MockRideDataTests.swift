import Foundation
import Testing
@testable import Fareline

/// Covers the mock riders' phone numbers, which must never reach a real person.
struct MockRideDataTests {
    /// Every mock rider, from both the repeating offers and the seeded waiting list.
    static let riders: [Rider] = {
        let offered = (0..<MockRideData.repeatingRiderCount).map {
            MockRideData.makeRide(sequence: $0, requestedAt: TestFixtures.date).rider
        }
        let waiting = MockRideData.passedOverRides(at: TestFixtures.date).map(\.rider)
        return offered + waiting
    }()

    @Test(arguments: riders)
    func riderHasAFictionalNumber(rider: Rider) {
        // 555-0100 to 555-0199 is the range reserved for fiction.
        #expect(
            rider.phoneNumber?.wholeMatch(of: /202-555-01\d\d/) != nil,
            "\(rider.name.formatted()) has \(rider.phoneNumber ?? "no number")"
        )
    }

    @Test func everyRiderHasADifferentNumber() {
        let numbers = Self.riders.compactMap(\.phoneNumber)

        #expect(Set(numbers).count == Self.riders.count)
    }
}
