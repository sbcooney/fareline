import Testing
@testable import Fareline

struct RideStatusTests {
    /// Pairs every status with every event in `TestFixtures.rideEvents`.
    ///
    /// New statuses are covered automatically. `RideEvent` has associated values and can't be `CaseIterable`,
    /// so new events must also be added to that list.
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
