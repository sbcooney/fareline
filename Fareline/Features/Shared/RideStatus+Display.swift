import Foundation

extension RideStatus {
    /// What's happening on the ride, from the driver's point of view.
    var title: LocalizedStringResource {
        switch self {
        case .awaitingDriver:
            "Waiting for a Driver"
        case .driverEnRoute:
            "Heading to Pickup"
        case .driverArrived:
            "At Pickup"
        case .inProgress:
            "On Trip"
        case .completed:
            "Completed"
        case .cancelled:
            "Cancelled"
        }
    }

    /// The title of the driver's next step, or `nil` if the driver has no step to take.
    var nextStepTitle: LocalizedStringResource? {
        switch self {
        case .driverEnRoute:
            "I've Arrived"
        case .driverArrived:
            "Start Trip"
        case .inProgress:
            "Complete Trip"
        case .awaitingDriver, .completed, .cancelled:
            nil
        }
    }

    /// What cancelling means at this stage, for the driver to read before confirming, or `nil` if the driver
    /// isn't on the ride.
    var cancellationMessage: LocalizedStringResource? {
        switch self {
        case .driverEnRoute, .driverArrived:
            "You won't earn the fare for this ride, and the rider will need to find another driver."
        case .inProgress:
            """
            The rider is with you. You won't earn the fare for this trip, \
            so end it this way only if you can't complete it.
            """
        case .awaitingDriver, .completed, .cancelled:
            nil
        }
    }
}
