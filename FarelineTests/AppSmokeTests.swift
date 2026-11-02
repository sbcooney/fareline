import Testing
@testable import Fareline

/// Confirms the test target can load and use the app module.
///
/// Remove this once #2 adds real domain tests.
struct AppSmokeTests {
    @Test @MainActor func rootViewCanBeCreated() {
        _ = RootView()
    }
}
