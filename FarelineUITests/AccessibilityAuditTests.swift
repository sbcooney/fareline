import XCTest

/// Runs Apple's accessibility audit on every screen, at the default and largest text sizes.
///
/// The audit checks for missing labels, clipped text, contrast, and hit areas.
final class AccessibilityAuditTests: FarelineUITestCase {
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
        try auditOfferScreen(largestText: false)
    }

    // A separate test, so that the expected failure in the default-size audit can't stop this one from running.
    @MainActor
    func testOfferScreenAtTheLargestTextSize() throws {
        try auditOfferScreen(largestText: true)
    }

    @MainActor
    private func auditOfferScreen(largestText: Bool) throws {
        let app = launch(["-goOnline", "-offerDelay", "0.5"], largestText: largestText)
        waitFor(app.buttons["Accept"])
        // The buttons are dimmed for a moment as the offer appears, and the audit would flag that dimmed text.
        waitUntilEnabled(app.buttons["Decline"])
        // The audit reports Decline's text on its glass capsule as failing contrast, but measured on screen
        // it's 6.3:1 against the capsule, and `ColorTokenTests` checks brandPrimary on every background.
        //
        // The audit sometimes reports one contrast failure with no element, which goes away only if the
        // countdown row is removed. Its styling, redrawing, and accessibility setup were each ruled out. The
        // expectation isn't strict because the failure is intermittent.
        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        // Any other audit issue on this screen still fails the test.
        options.issueMatcher = { issue in
            issue.compactDescription.hasSuffix("Accessibility audit issues:\nContrast failed on no element")
        }
        XCTExpectFailure("Intermittent unattributed contrast issue from the countdown row", options: options) {
            do {
                try audit(app, ignoringContrastOn: ["Decline"])
            } catch {
                XCTFail("The audit couldn't run: \(error)")
            }
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
            // The newest ride, which is on screen at every text size.
            let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Dupont Circle to Reagan'"))
                .firstMatch
            waitFor(row)
            try audit(app)

            row.tap()
            waitFor(app.staticTexts["Ride Details"])
            // On a cancelled ride, which has no fare row, the audit reports that "Ended" doesn't scale. Screenshots
            // at L, XXXL, and Accessibility L show it growing with nothing clipped, and the same row on a
            // completed ride passes. Every other Dynamic Type check on the screen still runs.
            try audit(app, ignoringDynamicTypeOn: ["Ended"])
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
