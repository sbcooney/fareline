/// A reason a request to the ride backend failed.
///
/// Some cases, such as ``networkUnavailable``, would apply to a rider app too. Others are the driver's.
enum RideServiceError: Error {
    /// The service couldn't be reached. Nothing changed, so the request can be retried.
    case networkUnavailable

    /// The offer expired, was withdrawn, or its ride is no longer available.
    case offerNoLongerAvailable

    /// The ride isn't the driver's current ride, or it has already ended.
    case rideNoLongerAvailable

    /// The ride the driver tried to take from the waiting list has been taken by another driver, or its rider
    /// cancelled.
    case rideNoLongerWaiting

    /// The action isn't allowed in the current state, such as going offline during a ride or repeating a step.
    case actionNotAllowed
}
