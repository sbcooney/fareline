import Testing
@testable import Fareline

struct OfflineBannerTests {
    @Test(arguments: [
        (0, "No connection. Ride steps you take will be sent when it's back."),
        (1, "No connection. 1 ride step will be sent when it's back."),
        (3, "No connection. 3 ride steps will be sent when it's back.")
    ])
    func messageSaysHowManyStepsAreWaiting(pendingStepCount: Int, expected: String) {
        #expect(String(localized: OfflineBanner.message(pendingStepCount: pendingStepCount)) == expected)
    }
}
