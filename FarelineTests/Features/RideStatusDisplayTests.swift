import Testing
@testable import Fareline

struct RideStatusDisplayTests {
    static let beforePickup = "You won't earn the fare for this ride, and the rider will need to find another driver."
    static let onTrip = "The rider is with you. You won't earn the fare for this trip, "
        + "so end it this way only if you can't complete it."

    @Test(arguments: [
        (RideStatus.driverEnRoute, beforePickup),
        (.driverArrived, beforePickup),
        (.inProgress, onTrip)
    ])
    func cancellationMessageExplainsTheConsequence(status: RideStatus, expected: String) throws {
        let message = try #require(status.cancellationMessage)

        #expect(String(localized: message) == expected)
    }

    @Test(arguments: [RideStatus.awaitingDriver, .completed, .cancelled])
    func rideTheDriverIsntOnHasNoCancellationMessage(status: RideStatus) {
        #expect(status.cancellationMessage == nil)
    }
}
