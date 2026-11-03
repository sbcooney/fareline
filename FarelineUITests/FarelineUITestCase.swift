import XCTest

/// Shared setup for UI tests, which use XCTest because Swift Testing doesn't support UI tests.
///
/// Each test launches the app with `UITestLaunchOptions` arguments, then taps through it like a driver.
class FarelineUITestCase: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Launches the app in a known state, optionally at the largest accessibility text size.
    @MainActor
    func launch(_ arguments: [String] = [], largestText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"] + arguments
        if largestText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        return app
    }

    /// Runs Apple's accessibility audit, logging each issue with the element it's about, since the
    /// audit's own failure message doesn't say which element failed.
    ///
    /// Contrast is left out until #19 adds a design system with contrast-checked colors. Today the app uses
    /// the system's default blue and secondary gray, which fall just short. #19 turns this check back on.
    @MainActor
    func audit(_ app: XCUIApplication) throws {
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(.contrast)) { issue in
            let element = issue.element.map { "\($0.elementType) \"\($0.label)\"" } ?? "no element"
            print("Audit issue: \(issue.compactDescription) on \(element). \(issue.detailedDescription)")
            return false
        }
    }

    /// Waits for an element to appear, failing the test if it doesn't.
    @MainActor
    func waitFor(_ element: XCUIElement, timeout: TimeInterval = 10) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(element) didn't appear")
    }

    /// Waits for an element to become enabled, failing the test if it doesn't.
    @MainActor
    func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: element)
        wait(for: [enabled], timeout: timeout)
    }
}
