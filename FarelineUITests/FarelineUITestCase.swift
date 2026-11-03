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

    /// Runs Apple's accessibility audit, and fails once listing every issue with the element it's about.
    ///
    /// The audit's own failures stop at the first issue and don't say which element it was.
    ///
    /// - Parameters:
    ///   - types: The checks to run. Each use that leaves one out explains why.
    ///   - ignoredLabels: Buttons whose contrast is checked another way. Each use explains why.
    ///   - ignoredTextLabels: Text whose Dynamic Type support is checked another way. Each use explains why.
    @MainActor
    func audit(
        _ app: XCUIApplication,
        for types: XCUIAccessibilityAuditType = .all,
        ignoringContrastOn ignoredLabels: Set<String> = [],
        ignoringDynamicTypeOn ignoredTextLabels: Set<String> = []
    ) throws {
        var issues: [String] = []
        try app.performAccessibilityAudit(for: types) { issue in
            if issue.auditType == .contrast,
               let element = issue.element,
               element.elementType == .button,
               ignoredLabels.contains(element.label) {
                return true
            }
            if issue.auditType == .dynamicType,
               let element = issue.element,
               element.elementType == .staticText,
               ignoredTextLabels.contains(element.label) {
                return true
            }
            let element = issue.element.map { "\($0.elementType) \"\($0.label)\"" } ?? "no element"
            issues.append("\(issue.compactDescription) on \(element)")
            // Each issue is recorded here and reported together below.
            return true
        }
        XCTAssertTrue(issues.isEmpty, "Accessibility audit issues:\n" + issues.joined(separator: "\n"))
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
