/// The outcome of a ride offer.
enum RideOfferStatus: CaseIterable, Hashable, Sendable {
    /// The offer is waiting for a response.
    case pending

    /// The driver took the ride.
    case accepted

    /// The driver turned the ride down.
    case declined

    /// The offer ran out of time without a response.
    case expired
}
