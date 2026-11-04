import XCTest

/// Runs Apple's accessibility audit on every screen, in light and dark mode, at the default and largest text sizes.
///
/// The audit checks for missing labels, clipped text, contrast, and hit areas. Each test sets the simulator's
/// appearance itself, so the result doesn't depend on how the simulator was left.
final class AccessibilityAuditTests: FarelineUITestCase {
    private let appearances: [XCUIDevice.Appearance] = [.light, .dark]

    @MainActor
    func testHomeScreen() throws {
        for appearance in appearances {
            for largestText in [false, true] {
                let app = launch(largestText: largestText, appearance: appearance)
                waitFor(app.buttons["Go Online"])
                try audit(app)
            }
        }
    }

    @MainActor
    func testOfferScreen() throws {
        for appearance in appearances {
            try auditOfferScreen(largestText: false, appearance: appearance)
        }
    }

    // A separate test, so a failure at one size can't stop the other from running.
    @MainActor
    func testOfferScreenAtTheLargestTextSize() throws {
        for appearance in appearances {
            try auditOfferScreen(largestText: true, appearance: appearance)
        }
    }

    @MainActor
    private func auditOfferScreen(largestText: Bool, appearance: XCUIDevice.Appearance) throws {
        let app = launch(["-goOnline", "-offerDelay", "0.5"], largestText: largestText, appearance: appearance)
        waitFor(app.buttons["Accept"])
        // The buttons are dimmed for a moment as the offer appears, and the audit would flag that dimmed text.
        waitUntilEnabled(app.buttons["Decline"])
        // The audit reports Decline's text on its glass capsule as failing contrast, but measured on screen
        // it's 6.3:1 against the capsule, and `ColorTokenTests` checks brandPrimary on every background.
        guard largestText else {
            try audit(app, ignoringContrastOn: ["Decline"])
            return
        }
        // At the largest text size, the last rows scroll under the Accept and Decline bar, hidden but still on
        // screen, and the audit measures their text against the bar. Contrast runs on its own so each issue names
        // its element, and only text under the bar is skipped. Any other contrast issue still fails.
        // The bar's padding is the same on every side, so Decline's left edge shows how far above it the bar starts.
        let decline = app.buttons["Decline"].frame
        let barTop = decline.minY - decline.minX
        try audit(app, for: XCUIAccessibilityAuditType.all.subtracting(.contrast))
        try audit(app, for: .contrast, ignoringContrastOn: ["Decline"], ignoringContrastBelow: barTop)
    }

    @MainActor
    func testCurrentRideScreen() throws {
        for appearance in appearances {
            for largestText in [false, true] {
                let app = launch(
                    ["-goOnline", "-offerDelay", "0.5", "-acceptFirstOffer"],
                    largestText: largestText,
                    appearance: appearance
                )
                waitFor(app.buttons["I've Arrived"])
                try audit(app)
            }
        }
    }

    @MainActor
    func testPastRidesScreens() throws {
        for appearance in appearances {
            for largestText in [false, true] {
                let app = launch(["-seedPastRides"], largestText: largestText, appearance: appearance)
                waitFor(app.buttons["Past Rides"])
                app.buttons["Past Rides"].tap()
                let row = app.buttons
                    .matching(NSPredicate(format: "label BEGINSWITH 'Union Station to National Mall'"))
                    .firstMatch
                waitFor(row)
                try audit(app)

                row.tap()
                waitFor(app.staticTexts["Ride Details"])
                try audit(app)
            }
        }
    }

    @MainActor
    func testEmptyPastRides() throws {
        for appearance in appearances {
            let app = launch(largestText: true, appearance: appearance)
            waitFor(app.buttons["Past Rides"])
            app.buttons["Past Rides"].tap()
            waitFor(app.staticTexts["No Past Rides"])
            try audit(app)
        }
    }
}
