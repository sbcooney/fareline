import Foundation

extension RideServiceError {
    /// An explanation of the failure that can be shown to the driver.
    var message: LocalizedStringResource {
        switch self {
        case .networkUnavailable:
            "Fareline couldn't connect. Check your connection and try again."
        case .offerNoLongerAvailable:
            "This ride offer is no longer available."
        case .rideNoLongerAvailable:
            "This ride is no longer available."
        case .actionNotAllowed:
            "You can't do that right now."
        }
    }
}
