import Testing
@testable import Fareline

struct OfflineBannerTests {
    @Test(arguments: [
        (0, "You're offline. Ride steps you take will be sent when you reconnect."),
        (1, "You're offline. 1 ride step will be sent when you reconnect."),
        (3, "You're offline. 3 ride steps will be sent when you reconnect.")
    ])
    func messageSaysHowManyStepsAreWaiting(pendingStepCount: Int, expected: String) {
        #expect(String(localized: OfflineBanner.message(pendingStepCount: pendingStepCount)) == expected)
    }
}
