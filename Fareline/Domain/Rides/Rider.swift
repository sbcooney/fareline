import Foundation

/// A person requesting or taking a ride.
struct Rider: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: PersonNameComponents
}
