import Foundation

/// Something the driver needs to read and acknowledge.
///
/// Both kinds share one type so that only one shows at a time. ``DriverModel`` decides which wins.
enum DriverAlert: Equatable {
    /// An action failed.
    case error(RideServiceError)

    /// The rider cancelled the driver's ride.
    case riderCancelled(Ride)

    /// The service refused a ride step the driver took offline, so it and any after it weren't sent.
    case offlineStepsNotSent

    var title: LocalizedStringResource {
        switch self {
        case .error:
            "Something Went Wrong"
        case .riderCancelled:
            "Ride Cancelled"
        case .offlineStepsNotSent:
            "Ride Steps Not Sent"
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .error(let error):
            error.message
        case .riderCancelled(let ride):
            "\(ride.rider.name.formatted()) cancelled the ride. You're available for new offers."
        case .offlineStepsNotSent:
            "Some steps you took offline couldn't be sent. Your ride shows its latest state."
        }
    }
}
