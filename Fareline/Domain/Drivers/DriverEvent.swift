/// Something that happens to a driver and can change their availability.
enum DriverEvent: CaseIterable, Hashable, Sendable {
    /// The driver chose to start taking rides.
    case wentOnline

    /// The driver chose to stop taking rides.
    case wentOffline

    /// The driver took a ride.
    case rideAssigned

    /// The driver's ride completed or was cancelled.
    case rideEnded
}
