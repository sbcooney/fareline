/// Whether a driver can take rides.
///
/// This is separate from ``RideStatus`` because it describes the driver rather than a ride. A driver
/// has an availability with or without a ride, and a rider app would need only the ride's status.
///
/// Valid transitions:
///
/// | From        | Event          | To          |
/// |-------------|----------------|-------------|
/// | `offline`   | `wentOnline`   | `available` |
/// | `available` | `wentOffline`  | `offline`   |
/// | `available` | `rideAssigned` | `onRide`    |
/// | `onRide`    | `rideEnded`    | `available` |
///
/// A driver on a ride can't go offline until the ride ends.
enum DriverAvailability: CaseIterable, Sendable {
    case offline
    case available
    case onRide

    /// Returns the availability that results from an event.
    ///
    /// - Throws: ``DriverTransitionError`` if the event isn't valid from this availability.
    func applying(_ event: DriverEvent) throws(DriverTransitionError) -> DriverAvailability {
        switch (self, event) {
        case (.offline, .wentOnline):
            .available
        case (.available, .wentOffline):
            .offline
        case (.available, .rideAssigned):
            .onRide
        case (.onRide, .rideEnded):
            .available
        default:
            throw DriverTransitionError(availability: self, event: event)
        }
    }
}
