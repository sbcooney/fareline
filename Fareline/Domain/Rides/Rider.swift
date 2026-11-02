import Foundation

/// A person requesting or taking a ride.
struct Rider: Equatable, Sendable {
    let id: UUID
    let name: PersonNameComponents
}
