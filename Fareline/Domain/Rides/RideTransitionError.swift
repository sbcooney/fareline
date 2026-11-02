/// An event that isn't valid for a ride's current status.
struct RideTransitionError: Error, Equatable, Sendable {
    let status: RideStatus
    let event: RideEvent
}
