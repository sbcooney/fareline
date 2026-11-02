import Foundation

/// Something that happens to a ride and can change its status.
enum RideEvent: Equatable, Sendable {
    /// A driver took the ride.
    case driverAssigned(driverID: Driver.ID)

    /// The driver reached the pickup location.
    case driverArrived

    /// The rider was picked up and the trip began.
    case tripStarted

    /// The trip ended at the given time.
    ///
    /// The time is passed in, rather than read from the system clock, to keep the domain deterministic.
    case tripCompleted(date: Date)

    /// The ride was cancelled before the trip began.
    case cancelled
}
