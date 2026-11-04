import Testing
@testable import Fareline

struct ConnectionMessageTests {
    @Test(arguments: [
        (0, "Connection restored."),
        (1, "Connection restored. Sending 1 ride step."),
        (3, "Connection restored. Sending 3 ride steps.")
    ])
    func restoredToastSaysWhatsBeingSent(pendingStepCount: Int, expected: String) {
        #expect(String(localized: ConnectionToast.restoredMessage(pendingStepCount: pendingStepCount)) == expected)
    }

    @Test(arguments: [
        (0, "No connection. Ride steps you take will be sent when it's back."),
        (1, "No connection. 1 ride step will be sent when it's back."),
        (2, "No connection. 2 ride steps will be sent when it's back.")
    ])
    func statusExplainsWhatsWaitingAndWhatNeedsAConnection(pendingStepCount: Int, expected: String) {
        let explanation = String(localized: ConnectionStatusButton.explanation(pendingStepCount: pendingStepCount))

        #expect(explanation == expected + " Offers, changing your status, and taking a ride need a connection.")
    }
}
