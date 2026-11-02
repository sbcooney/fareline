/// A reason a ride offer can't change as requested.
enum RideOfferError: Error, Equatable {
    /// The offer has already been accepted, declined, or expired.
    case alreadyResolved(RideOfferStatus)

    /// The response came at or after the offer's expiry time.
    case responseTooLate

    /// The offer's expiry time hasn't been reached.
    case notYetExpired
}
