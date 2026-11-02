/// A complete snapshot of everything the service knows about the current driver.
///
/// The service always sends whole snapshots rather than individual changes. This means a client can't
/// end up with an offer, ride, and driver that disagree, because it replaces all of them at once.
struct DriverSession: Equatable, Sendable {
    /// Increases with each change, so a client can recognize and ignore a snapshot that arrives late.
    let version: Int
    let driver: Driver

    /// The offer waiting for the driver's response, if any.
    let pendingOffer: RideOffer?

    /// The ride the driver is currently on, if any.
    let activeRide: Ride?

    /// The driver's completed rides, newest first.
    let completedRides: [Ride]
}
