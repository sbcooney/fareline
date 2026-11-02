import Testing
@testable import Fareline

struct RideStatusTests {
    /// Every status is paired with every event, so adding a case can't silently skip coverage.
    /// The expected result is written out separately from the production switch to catch mistakes in it.
    @Test(arguments: RideStatus.allCases, TestFixtures.rideEvents)
    func transitionMatchesTheLifecycle(status: RideStatus, event: RideEvent) throws {
        if let expected = expectedStatus(from: status, on: event) {
            #expect(try status.applying(event) == expected)
        } else {
            #expect(throws: RideTransitionError(status: status, event: event)) {
                try status.applying(event)
            }
        }
    }

    private func expectedStatus(from status: RideStatus, on event: RideEvent) -> RideStatus? {
        switch event {
        case .driverAssigned:
            status == .awaitingDriver ? .driverEnRoute : nil
        case .driverArrived:
            status == .driverEnRoute ? .driverArrived : nil
        case .tripStarted:
            status == .driverArrived ? .inProgress : nil
        case .tripCompleted:
            status == .inProgress ? .completed : nil
        case .cancelled:
            [.awaitingDriver, .driverEnRoute, .driverArrived].contains(status) ? .cancelled : nil
        }
    }
}
