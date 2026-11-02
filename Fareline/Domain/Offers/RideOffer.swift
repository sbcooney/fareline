import Foundation

/// A proposal of one ride to one driver, with a time limit.
///
/// An offer's outcome is separate from the ride's status. Declining or ignoring an offer ends the offer,
/// while the ride stays `awaitingDriver` and can be offered to someone else or claimed from the rider queue.
///
/// Valid transitions:
///
/// | From      | Action      | Requires              | To         |
/// |-----------|-------------|-----------------------|------------|
/// | `pending` | ``accept(at:)``  | before `expiresAt`    | `accepted` |
/// | `pending` | ``decline(at:)`` | before `expiresAt`    | `declined` |
/// | `pending` | ``expire(at:)``  | `expiresAt` or later  | `expired`  |
///
/// Accepting an offer doesn't update the ride or driver. Whatever coordinates the three applies those changes,
/// so this type stays limited to the offer's own rules.
struct RideOffer: Identifiable, Hashable, Sendable {
    let id: UUID

    /// The ride being offered, as it was when the offer was made.
    ///
    /// This is a snapshot for display and may be out of date. Check the current ride before acting on an offer.
    let ride: Ride

    /// The driver receiving the offer.
    let driverID: Driver.ID

    /// The moment the offer stops accepting responses.
    let expiresAt: Date

    private(set) var status = RideOfferStatus.pending

    init(id: UUID, ride: Ride, driverID: Driver.ID, expiresAt: Date) {
        self.id = id
        self.ride = ride
        self.driverID = driverID
        self.expiresAt = expiresAt
    }

    /// Records that the driver accepted the offer.
    ///
    /// The time is checked here because a response can arrive after the countdown ends, such as when a
    /// tap races the expiry timer.
    ///
    /// - Parameter date: The time of the response.
    /// - Throws: ``RideOfferError`` if the offer is resolved or has run out of time.
    mutating func accept(at date: Date) throws(RideOfferError) {
        try validateResponse(at: date)
        status = .accepted
    }

    /// Records that the driver declined the offer.
    ///
    /// - Parameter date: The time of the response.
    /// - Throws: ``RideOfferError`` if the offer is resolved or has run out of time.
    mutating func decline(at date: Date) throws(RideOfferError) {
        try validateResponse(at: date)
        status = .declined
    }

    /// Records that the offer ran out of time.
    ///
    /// - Parameter date: The current time.
    /// - Throws: ``RideOfferError`` if the offer is resolved or hasn't reached its expiry time.
    mutating func expire(at date: Date) throws(RideOfferError) {
        guard status == .pending else {
            throw .alreadyResolved(status)
        }
        guard date >= expiresAt else {
            throw .notYetExpired
        }
        status = .expired
    }

    private func validateResponse(at date: Date) throws(RideOfferError) {
        guard status == .pending else {
            throw .alreadyResolved(status)
        }
        guard date < expiresAt else {
            throw .responseTooLate
        }
    }
}
