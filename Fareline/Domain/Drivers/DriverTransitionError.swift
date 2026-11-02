/// An event that isn't valid for a driver's current availability.
struct DriverTransitionError: Error, Equatable {
    let availability: DriverAvailability
    let event: DriverEvent
}
