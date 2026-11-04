import Foundation

/// The boundary between the app and whatever provides ride data.
///
/// This models what a real backend would provide. The backend owns the rules that span a driver and other
/// people, such as who gets offered which ride, so the app only sends requests and displays the results.
/// The current driver is implied, as it would be by an authenticated connection.
///
/// Each request returns the resulting session. Changes that the driver didn't request, such as a new offer
/// or a cancelled ride, arrive through ``sessionUpdates()``.
protocol RideService: Sendable {
    /// Returns a stream that immediately provides the current session, followed by each later change.
    ///
    /// While the connection is down, nothing arrives, and the latest session follows when it returns.
    func sessionUpdates() async -> AsyncStream<DriverSession>

    /// Returns a stream that immediately provides whether the connection is up, followed by each change.
    ///
    /// Nothing polls for this. A client of a real backend would feed it from `NWPathMonitor`, which reports
    /// changes as they happen.
    func connectionUpdates() async -> AsyncStream<Bool>

    /// Makes the driver available for rides.
    func goOnline() async throws(RideServiceError) -> DriverSession

    /// Stops the driver from receiving rides.
    func goOffline() async throws(RideServiceError) -> DriverSession

    /// Accepts an offer, assigning its ride to the driver.
    func acceptOffer(id: RideOffer.ID) async throws(RideServiceError) -> DriverSession

    /// Declines an offer, leaving its ride available for other drivers.
    func declineOffer(id: RideOffer.ID) async throws(RideServiceError) -> DriverSession

    /// Records that the driver reached the pickup location.
    func markArrived(rideID: Ride.ID) async throws(RideServiceError) -> DriverSession

    /// Records that the rider was picked up.
    func startTrip(rideID: Ride.ID) async throws(RideServiceError) -> DriverSession

    /// Records that the trip ended, and makes the driver available again.
    ///
    /// - Parameter date: When the driver completed the trip, which may be earlier than this request if it was
    ///   queued while offline.
    func completeTrip(rideID: Ride.ID, at date: Date) async throws(RideServiceError) -> DriverSession

    /// Takes a ride from the waiting list, and starts it as accepting an offer does. A pending offer is declined,
    /// as the driver has chosen another ride.
    func claimRide(rideID: Ride.ID) async throws(RideServiceError) -> DriverSession

    /// Cancels the driver's current ride, at any stage from accepting it until the trip ends, and makes the driver
    /// available again. The driver earns no fare.
    ///
    /// - Parameter date: When the driver cancelled, which may be earlier than this request if it was queued while
    ///   offline.
    func cancelRide(rideID: Ride.ID, at date: Date) async throws(RideServiceError) -> DriverSession
}
