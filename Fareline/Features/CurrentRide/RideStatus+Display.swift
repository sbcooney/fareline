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
}
