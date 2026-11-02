import Foundation

/// A person who gives rides.
///
/// A new driver starts `offline`, and their availability changes only through ``apply(_:)``.
struct Driver: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: PersonNameComponents

    private(set) var availability = DriverAvailability.offline

    init(id: UUID, name: PersonNameComponents) {
        self.id = id
        self.name = name
    }

    /// Updates the driver's availability.
    ///
    /// The driver is unchanged if the event is invalid.
    ///
    /// - Throws: ``DriverTransitionError`` if the event isn't valid from the current availability.
    mutating func apply(_ event: DriverEvent) throws(DriverTransitionError) {
        availability = try availability.applying(event)
    }
}
