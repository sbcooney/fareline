import XCTest

/// Covers how offers reach the driver, which depends on view state that unit tests can't reach.
final class OfferUITests: FarelineUITestCase {
    @MainActor
    func testOfferOnAPushedScreenShowsABannerThatOpensIt() {
        let app = launch(["-seedPastRides", "-goOnline", "-offerDelay", "3"])
        waitFor(app.buttons["Past Rides"])
        app.buttons["Past Rides"].tap()
        let banner = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'New Ride Offer'")).firstMatch
        waitFor(banner)

        // The driver keeps their place until they choose to open the offer.
        XCTAssertTrue(app.navigationBars["Past Rides"].exists)
        banner.tap()

        waitFor(app.buttons["Accept"])
        XCTAssertFalse(app.navigationBars["Past Rides"].exists)
    }

    @MainActor
    func testCountdownIsSpokenAsTimeRemaining() {
        let app = launch(["-goOnline", "-offerDelay", "0.5"])
        waitFor(app.buttons["Accept"])

        // The row is one combined element, so it isn't a static text.
        let countdown = app.otherElements["Time Left"]
        waitFor(countdown)

        let value = countdown.value as? String ?? ""
        XCTAssertTrue(value.hasSuffix("seconds"), "VoiceOver should hear the time left, not \"\(value)\"")
    }

    /// Checks that Accept works once ready. Whether it ignores taps at first can't be checked here, because
    /// XCUITest waits for the offer screen's animation to finish, which takes longer than the delay.
    @MainActor
    func testAcceptWorksOnceTheOfferHasSettled() {
        let app = launch(["-goOnline", "-offerDelay", "1"])
        let accept = app.buttons["Accept"]
        waitFor(accept, timeout: 5)
        waitUntilEnabled(accept)

        accept.tap()

        waitFor(app.buttons["I've Arrived"])
    }

    /// Like the Accept test, this can't check the delay itself, because XCUITest's timing varies by more than it.
    @MainActor
    func testGoOfflineWorksOnceItHasSettled() {
        let app = launch(["-offerDelay", "60"])
        let goOnline = app.buttons["Go Online"]
        waitFor(goOnline)
        waitUntilEnabled(goOnline)
        goOnline.tap()

        let goOffline = app.buttons["Go Offline"]
        waitFor(goOffline)
        waitUntilEnabled(goOffline)
        goOffline.tap()

        waitFor(app.buttons["Go Online"])
    }
}
