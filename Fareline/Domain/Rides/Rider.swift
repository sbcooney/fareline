import Foundation

/// A person requesting or taking a ride.
struct Rider: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: PersonNameComponents
}
