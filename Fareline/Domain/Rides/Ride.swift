import Foundation

/// A trip from a pickup location to a drop-off location.
///
/// A new ride always starts as `awaitingDriver`. Its status, driver, and end time change only
/// through ``apply(_:)``, so a ride can't be in a state its lifecycle doesn't allow, such as
/// `driverEnRoute` with no driver.
struct Ride: Identifiable, Equatable, Sendable {
    let id: UUID
    let rider: Rider
    let pickup: Place
    let dropoff: Place
    let fare: Fare
    let requestedAt: Date

    private(set) var status = RideStatus.awaitingDriver
    private(set) var driverID: Driver.ID?
    /// When the ride was completed or cancelled. The status says which.
    private(set) var endedAt: Date?

    init(id: UUID, rider: Rider, pickup: Place, dropoff: Place, fare: Fare, requestedAt: Date) {
        self.id = id
        self.rider = rider
        self.pickup = pickup
        self.dropoff = dropoff
        self.fare = fare
        self.requestedAt = requestedAt
    }

    /// Advances the ride through its lifecycle.
    ///
    /// The ride is unchanged if the event is invalid.
    ///
    /// - Throws: ``RideTransitionError`` if the event isn't valid from the current status.
    mutating func apply(_ event: RideEvent) throws(RideTransitionError) {
        status = try status.applying(event)

        switch event {
        case .driverAssigned(let driverID):
            self.driverID = driverID
        case .tripCompleted(let date), .cancelled(let date):
            endedAt = date
        case .driverArrived, .tripStarted:
            break
        }
    }
}
