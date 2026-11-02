/// The stage of a ride's lifecycle.
///
/// Statuses describe the ride itself rather than one participant's view of it, so any
/// client, such as a future rider app, can read the same values.
///
/// Valid transitions:
///
/// | From             | Event            | To               |
/// |------------------|------------------|------------------|
/// | `awaitingDriver` | `driverAssigned` | `driverEnRoute`  |
/// | `driverEnRoute`  | `driverArrived`  | `driverArrived`  |
/// | `driverArrived`  | `tripStarted`    | `inProgress`     |
/// | `inProgress`     | `tripCompleted`  | `completed`      |
/// | `awaitingDriver` | `cancelled`      | `cancelled`      |
/// | `driverEnRoute`  | `cancelled`      | `cancelled`      |
/// | `driverArrived`  | `cancelled`      | `cancelled`      |
///
/// `completed` and `cancelled` are terminal. A ride can't be cancelled once it's in progress.
enum RideStatus: String, CaseIterable, Hashable, Codable, Sendable {
    case awaitingDriver
    case driverEnRoute
    case driverArrived
    case inProgress
    case completed
    case cancelled

    /// Returns the status that results from an event.
    ///
    /// - Throws: ``RideTransitionError`` if the event isn't valid from this status.
    func applying(_ event: RideEvent) throws(RideTransitionError) -> RideStatus {
        switch (self, event) {
        case (.awaitingDriver, .driverAssigned):
            .driverEnRoute
        case (.driverEnRoute, .driverArrived):
            .driverArrived
        case (.driverArrived, .tripStarted):
            .inProgress
        case (.inProgress, .tripCompleted):
            .completed
        case (.awaitingDriver, .cancelled), (.driverEnRoute, .cancelled), (.driverArrived, .cancelled):
            .cancelled
        default:
            throw RideTransitionError(status: self, event: event)
        }
    }
}
