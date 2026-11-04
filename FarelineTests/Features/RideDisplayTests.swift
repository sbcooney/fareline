import Foundation
import Testing
@testable import Fareline

struct RideDisplayTests {
    @Test(arguments: [
        (0, "Waiting less than a minute"),
        (59, "Waiting less than a minute"),
        (60, "Waiting 1 minute"),
        (299, "Waiting 4 minutes"),
        (3_600, "Waiting 1 hour"),
        (3_900, "Waiting 1 hour, 5 minutes")
    ])
    func waitDescriptionCountsWholeMinutes(secondsWaited: TimeInterval, expected: String) {
        let ride = TestFixtures.ride()

        let description = ride.waitDescription(at: ride.requestedAt.addingTimeInterval(secondsWaited))

        #expect(String(localized: description) == expected)
    }

    @Test func waitDescriptionBeforeTheRequestTimeIsUnderAMinute() {
        // A clock that's slightly behind the service's shouldn't show a negative wait.
        let ride = TestFixtures.ride()

        let description = ride.waitDescription(at: ride.requestedAt.addingTimeInterval(-30))

        #expect(String(localized: description) == "Waiting less than a minute")
    }
}
