import Foundation
import Testing
@testable import Fareline

struct DriverTests {
    /// Every availability is paired with every event, so adding a case can't silently skip coverage.
    @Test(arguments: DriverAvailability.allCases, DriverEvent.allCases)
    func transitionMatchesTheRules(availability: DriverAvailability, event: DriverEvent) throws {
        if let expected = expectedAvailability(from: availability, on: event) {
            #expect(try availability.applying(event) == expected)
        } else {
            #expect(throws: DriverTransitionError(availability: availability, event: event)) {
                try availability.applying(event)
            }
        }
    }

    @Test func newDriverIsOffline() {
        #expect(makeDriver().availability == .offline)
    }

    @Test func driverOnARideCantGoOffline() throws {
        var driver = makeDriver()
        try driver.apply(.wentOnline)
        try driver.apply(.rideAssigned)

        #expect(throws: DriverTransitionError(availability: .onRide, event: .wentOffline)) {
            try driver.apply(.wentOffline)
        }
        #expect(driver.availability == .onRide)
    }

    private func expectedAvailability(
        from availability: DriverAvailability,
        on event: DriverEvent
    ) -> DriverAvailability? {
        switch (availability, event) {
        case (.offline, .wentOnline):
            .available
        case (.available, .wentOffline):
            .offline
        case (.available, .rideAssigned):
            .onRide
        case (.onRide, .rideEnded):
            .available
        default:
            nil
        }
    }

    private func makeDriver() -> Driver {
        Driver(
            id: TestFixtures.driverID,
            name: PersonNameComponents(givenName: "Grace", familyName: "Hopper")
        )
    }
}
