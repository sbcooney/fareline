/// A ride step the driver took while offline, waiting to be sent when the connection returns.
struct PendingRideStep {
    /// The ride the driver was looking at.
    let rideID: Ride.ID

    /// The step, as the domain describes it, so the ride on screen can move forward by the same rules the service
    /// uses. A completion or cancellation carries the time the driver tapped.
    let event: RideEvent
}
