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

    @Test(arguments: RideStatus.allCases, [RideRole.rider, .driver])
    func canBeCancelledMatchesTheLifecycle(status: RideStatus, role: RideRole) {
        let cancellation = RideEvent.cancelled(by: role, date: TestFixtures.date)

        #expect(status.canBeCancelled(by: role) == (expectedStatus(from: status, on: cancellation) != nil))
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
        case .cancelled(by: .rider, _):
            // A rider can cancel until they're in the car.
            [.awaitingDriver, .driverEnRoute, .driverArrived].contains(status) ? .cancelled : nil
        case .cancelled(by: .driver, _):
            // A driver can cancel only a ride they're on, including during the trip.
            [.driverEnRoute, .driverArrived, .inProgress].contains(status) ? .cancelled : nil
        }
    }
}
