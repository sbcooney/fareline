/// An event that isn't valid for a driver's current availability.
struct DriverTransitionError: Error, Equatable, Sendable {
    let availability: DriverAvailability
    let event: DriverEvent
}
