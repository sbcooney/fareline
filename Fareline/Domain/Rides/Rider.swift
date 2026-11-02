import Foundation

/// A person requesting or taking a ride.
struct Rider: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: PersonNameComponents
}
