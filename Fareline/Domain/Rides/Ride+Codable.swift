import Foundation

/// Saves a ride's fields, and rebuilds a saved ride through the domain's rules.
///
/// Synthesized decoding would set the status, driver, and end time directly, so a damaged file could
/// produce a ride the lifecycle doesn't allow, such as `completed` with no driver. Decoding instead replays
/// the events that lead to the saved status, then checks the result matches what was saved.
extension Ride: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, rider, pickup, dropoff, fare, requestedAt, status, driverID, endedAt, cancelledBy
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            rider: try container.decode(Rider.self, forKey: .rider),
            pickup: try container.decode(Place.self, forKey: .pickup),
            dropoff: try container.decode(Place.self, forKey: .dropoff),
            fare: try container.decode(Fare.self, forKey: .fare),
            requestedAt: try container.decode(Date.self, forKey: .requestedAt)
        )
        let status = try container.decode(RideStatus.self, forKey: .status)
        let driverID = try container.decodeIfPresent(Driver.ID.self, forKey: .driverID)
        let endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        // Rides saved before cancellations recorded who cancelled were all cancelled by riders.
        let cancelledBy = try container.decodeIfPresent(RideRole.self, forKey: .cancelledBy)
            ?? (status == .cancelled ? .rider : nil)

        do {
            for event in Self.events(leadingTo: status, driverID: driverID, endedAt: endedAt, cancelledBy: cancelledBy) {
                try apply(event)
            }
        } catch {
            throw Self.invalidState(in: container)
        }
        guard self.status == status,
              self.driverID == driverID,
              self.endedAt == endedAt,
              self.cancelledBy == cancelledBy else {
            throw Self.invalidState(in: container)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(rider, forKey: .rider)
        try container.encode(pickup, forKey: .pickup)
        try container.encode(dropoff, forKey: .dropoff)
        try container.encode(fare, forKey: .fare)
        try container.encode(requestedAt, forKey: .requestedAt)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(driverID, forKey: .driverID)
        try container.encodeIfPresent(endedAt, forKey: .endedAt)
        try container.encodeIfPresent(cancelledBy, forKey: .cancelledBy)
    }

    /// Returns the events that take a new ride to the given status.
    ///
    /// A cancelled ride's events depend on whether a driver was assigned. How far the ride got before it was
    /// cancelled isn't saved, and doesn't change the result.
    private static func events(
        leadingTo status: RideStatus,
        driverID: Driver.ID?,
        endedAt: Date?,
        cancelledBy: RideRole?
    ) -> [RideEvent] {
        let assigned = driverID.map { [RideEvent.driverAssigned(driverID: $0)] } ?? []
        // A missing end time makes the event list incomplete, so replaying it fails to reach the saved status.
        let ended = endedAt.map { [$0] } ?? []
        switch status {
        case .awaitingDriver, .driverEnRoute:
            // A driver is what moves a ride from awaiting one to en route.
            return assigned
        case .driverArrived:
            return assigned + [.driverArrived]
        case .inProgress:
            return assigned + [.driverArrived, .tripStarted]
        case .completed:
            return assigned + [.driverArrived, .tripStarted] + ended.map { .tripCompleted(date: $0) }
        case .cancelled:
            // A missing canceller also leaves the list incomplete. Only a cancelled ride has one, so a canceller
            // saved on any other ride fails the check after replaying.
            guard let cancelledBy else {
                return assigned
            }
            return assigned + ended.map { .cancelled(by: cancelledBy, date: $0) }
        }
    }

    private static func invalidState(in container: KeyedDecodingContainer<CodingKeys>) -> DecodingError {
        .dataCorruptedError(
            forKey: .status,
            in: container,
            debugDescription: "The saved status, driver, and end time aren't a state the ride's lifecycle allows."
        )
    }
}
