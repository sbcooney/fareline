/// The rides that an offer ended without placing, which the waiting list shows while they still need a driver.
///
/// A ride's status can't say this, as being passed over is about dispatch rather than the ride's lifecycle. Rides that
/// have since been taken or cancelled stay recorded, and ``rides(in:)`` leaves them out by status.
struct WaitingList {
    private var rideIDs: Set<Ride.ID> = []

    mutating func add(_ id: Ride.ID) {
        rideIDs.insert(id)
    }

    /// Whether the ride has joined the list, even if it has since been taken or cancelled.
    func hasListed(_ id: Ride.ID) -> Bool {
        rideIDs.contains(id)
    }

    /// The listed rides that still need a driver, longest wait first.
    func rides(in rides: [Ride.ID: Ride]) -> [Ride] {
        rideIDs
            .compactMap { rides[$0] }
            .filter { $0.status == .awaitingDriver }
            // The ID breaks ties, so rides requested at the same moment keep one order between sessions.
            .sorted { ($0.requestedAt, $0.id.uuidString) < ($1.requestedAt, $1.id.uuidString) }
    }
}
