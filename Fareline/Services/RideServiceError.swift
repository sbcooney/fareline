/// A reason a ride service request failed.
enum RideServiceError: Error, Equatable, Sendable {
    /// The service couldn't be reached. Nothing changed, so the request can be retried.
    case networkUnavailable

    /// The offer expired, was withdrawn, or its ride is no longer available.
    case offerNoLongerAvailable

    /// The ride isn't the driver's current ride, or it has already ended.
    case rideNoLongerAvailable

    /// The action isn't allowed in the current state, such as going offline during a ride.
    case actionNotAllowed
}
