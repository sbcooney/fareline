import XCTest

/// Runs Apple's accessibility audit on every screen, at the default and largest text sizes.
///
/// The audit checks for missing labels, clipped text, contrast, and hit areas.
final class AccessibilityAuditTests: FarelineUITestCase {
    override func setUp() {
        // Report every issue on a screen, not just the first.
        continueAfterFailure = true
    }

    @MainActor
    func testHomeScreen() throws {
        for largestText in [false, true] {
            let app = launch(largestText: largestText)
            waitFor(app.buttons["Go Online"])
            try audit(app)
        }
    }

    @MainActor
    func testOfferScreen() throws {
        for largestText in [false, true] {
            let app = launch(["-goOnline", "-offerDelay", "0.5"], largestText: largestText)
            waitFor(app.buttons["Accept"])
            try audit(app)
        }
    }

    @MainActor
    func testCurrentRideScreen() throws {
        for largestText in [false, true] {
            let app = launch(["-goOnline", "-offerDelay", "0.5", "-acceptFirstOffer"], largestText: largestText)
            waitFor(app.buttons["I've Arrived"])
            try audit(app)
        }
    }

    @MainActor
    func testPastRidesScreens() throws {
        for largestText in [false, true] {
            let app = launch(["-seedPastRides"], largestText: largestText)
            waitFor(app.buttons["Past Rides"])
            app.buttons["Past Rides"].tap()
            let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Union Station to National Mall'"))
                .firstMatch
            waitFor(row)
            try audit(app)

            row.tap()
            waitFor(app.staticTexts["Ride Details"])
            try audit(app)
        }
    }

    @MainActor
    func testEmptyPastRides() throws {
        let app = launch(largestText: true)
        waitFor(app.buttons["Past Rides"])
        app.buttons["Past Rides"].tap()
        waitFor(app.staticTexts["No Past Rides"])
        try audit(app)
    }
}
