import XCTest

/// Covers the driver cancelling their ride, through the confirmation that unit tests can't reach.
final class RideCancellationUITests: FarelineUITestCase {
    @MainActor
    func testKeepingTheRideChangesNothingAndCancellingFreesTheDriver() {
        let app = launch(["-goOnline", "-offerDelay", "0.5", "-acceptFirstOffer"])
        waitFor(app.buttons["I've Arrived"])

        app.buttons["Cancel Ride"].tap()
        waitFor(app.staticTexts["Cancel This Ride?"])
        // The confirmation appears as a popover, which iOS shows without its cancel button. Tapping outside it
        // keeps the ride, as does VoiceOver's escape gesture.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()

        XCTAssertTrue(app.staticTexts["Cancel This Ride?"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["I've Arrived"].exists)

        app.buttons["Cancel Ride"].tap()
        waitFor(app.staticTexts["Cancel This Ride?"])
        app.sheets["Cancel This Ride?"].buttons["Cancel Ride"].tap()

        // The driver is available again: on the home screen, or already shown the next offer.
        waitFor(app.buttons.matching(NSPredicate(format: "label IN {'Go Offline', 'Accept'}")).firstMatch)
        XCTAssertFalse(app.buttons["I've Arrived"].exists)
    }

    @MainActor
    func testConfirmation() throws {
        for largestText in [false, true] {
            let app = launch(["-goOnline", "-offerDelay", "0.5", "-acceptFirstOffer"], largestText: largestText)
            waitFor(app.buttons["I've Arrived"])
            app.buttons["Cancel Ride"].tap()
            waitFor(app.staticTexts["Cancel This Ride?"])
            // The system draws the confirmation, and the audit reports two things the app can't change: its text
            // stops growing at large sizes, and the screen behind it can't be reached while it's open, which is
            // how it stays modal. Every other check still runs.
            try audit(app, for: XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .elementDetection]))
        }
    }
}
