import Testing
@testable import Fareline

struct RideRoleDisplayTests {
    @Test(arguments: [
        (RideRole.rider, "Cancelled by Rider"),
        (.driver, "Cancelled by You")
    ])
    func cancellationTitleSaysWhoCancelled(role: RideRole, expected: String) {
        #expect(String(localized: role.cancellationTitle) == expected)
    }
}
