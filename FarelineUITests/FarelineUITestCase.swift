import XCTest

/// Shared setup for UI tests, which use XCTest because Swift Testing doesn't support UI tests.
///
/// Each test launches the app with `UITestLaunchOptions` arguments, then taps through it like a driver.
class FarelineUITestCase: XCTestCase {
    /// Whether this test has changed the simulator's appearance, and so restores it when it ends.
    private var restoresAppearance = false

    override func setUp() {
        continueAfterFailure = false
    }

    /// Launches the app in a known state, optionally at the largest accessibility text size, and in light or dark mode.
    ///
    /// - Parameter appearance: The simulator's appearance for this launch, or `nil` to leave it as it is. The
    ///   simulator is put back as the test found it when the test ends, as the setting outlives the app.
    @MainActor
    func launch(
        _ arguments: [String] = [],
        largestText: Bool = false,
        appearance: XCUIDevice.Appearance? = nil
    ) -> XCUIApplication {
        if let appearance {
            if restoresAppearance == false {
                let original = XCUIDevice.shared.appearance
                addTeardownBlock { @MainActor in
                    XCUIDevice.shared.appearance = original
                }
                restoresAppearance = true
            }
            XCUIDevice.shared.appearance = appearance
        }
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
    ///   - types: The checks to run. Run contrast on its own when issues need their elements, as the full audit can
    ///     report a contrast issue without one.
    ///   - ignoredLabels: Buttons whose contrast is checked another way. Each use explains why.
    ///   - coveredTop: Text whose top is at or below this point, hidden behind a bar pinned to the bottom of the
    ///     screen. The audit measures hidden text against whatever covers it. Each use explains why.
    @MainActor
    func audit(
        _ app: XCUIApplication,
        for types: XCUIAccessibilityAuditType = .all,
        ignoringContrastOn ignoredLabels: Set<String> = [],
        ignoringContrastBelow coveredTop: CGFloat? = nil
    ) throws {
        var issues: [String] = []
        try app.performAccessibilityAudit(for: types) { issue in
            if issue.auditType == .contrast,
               let element = issue.element,
               element.elementType == .button,
               ignoredLabels.contains(element.label) {
                return true
            }
            if issue.auditType == .contrast,
               let coveredTop,
               let element = issue.element,
               element.elementType == .staticText,
               element.frame.minY >= coveredTop {
                return true
            }
            let element = issue.element.map { "\($0.elementType) \"\($0.label)\"" } ?? "no element"
            issues.append("\(issue.compactDescription) on \(element)")
            // Each issue is recorded here and reported together below.
            return true
        }
        let mode = XCUIDevice.shared.appearance == .dark ? "dark" : "light"
        XCTAssertTrue(issues.isEmpty, "Accessibility audit issues in \(mode) mode:\n" + issues.joined(separator: "\n"))
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
