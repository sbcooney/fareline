import Foundation

extension RideRole {
    /// How a ride this party cancelled is described in the driver's history.
    var cancellationTitle: LocalizedStringResource {
        switch self {
        case .rider:
            "Cancelled by Rider"
        case .driver:
            "Cancelled by You"
        }
    }
}
