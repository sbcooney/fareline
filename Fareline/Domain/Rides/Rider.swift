import Foundation

/// A person requesting or taking a ride.
struct Rider: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let name: PersonNameComponents

    /// A number the driver can call, in a format that's both shown and dialed, such as `202-555-0143`.
    ///
    /// Rides saved before riders had phone numbers have none.
    let phoneNumber: String?
}
