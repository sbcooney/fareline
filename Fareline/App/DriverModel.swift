import Observation

/// The app's single source of truth, and the one path for every user action.
///
/// Views read ``session`` and call intent methods such as ``acceptOffer(id:)``. The model doesn't apply
/// business rules itself. It sends requests to the service and replaces its state with the result, so
/// the app and the service can't disagree. Keeping all actions here also gives offline support one
/// place to queue them.
@MainActor
@Observable
final class DriverModel {
    /// The latest session, or `nil` until the first one arrives.
    private(set) var session: DriverSession?

    /// Whether a request is in progress. Views use this to show progress and prevent repeat taps.
    private(set) var isPerformingAction = false

    /// Whether the request in progress is cancelling the driver's ride, so views show progress on the control
    /// the driver used rather than on the ride's next step.
    private(set) var isCancellingRide = false

    /// What the driver needs to read and acknowledge, if anything.
    ///
    /// Only one alert shows at a time, so the model decides which explanation wins. Views set this to `nil`
    /// when the driver dismisses it.
    var alert: DriverAlert?

    /// The most recent offer that ended without the driver responding, such as one that expired.
    ///
    /// Sighted drivers see the offer screen go away, but VoiceOver users don't, so views announce this.
    private(set) var unansweredOfferID: RideOffer.ID?

    /// The offer the driver is responding to, or last responded to, so its ending isn't reported as unanswered.
    private var answeredOfferID: RideOffer.ID?

    /// Returns one of the driver's past rides, or `nil` if it isn't one.
    func pastRide(id: Ride.ID) -> Ride? {
        session?.pastRides.first { $0.id == id }
    }

    /// Whether the driver can change their availability now.
    ///
    /// This only decides what the control offers. The service still enforces the rule.
    var canChangeAvailability: Bool {
        guard isPerformingAction == false, let availability = session?.driver.availability else {
            return false
        }
        return availability != .onRide
    }

    private let service: any RideService

    init(service: any RideService) {
        self.service = service
    }

    /// Receives session updates until the calling task is cancelled.
    func start() async {
        for await session in await service.sessionUpdates() {
            apply(session)
        }
    }

    /// Updates the state, unless a newer session has already been applied.
    ///
    /// A request's result and a stream update travel separately, so they can arrive out of order.
    func apply(_ newSession: DriverSession) {
        if let session, newSession.version <= session.version {
            return
        }
        // A ride the rider cancelled is reported even if the session where it was active was skipped. The first
        // session is ignored, as its past rides are history rather than news. A driver has one ride at a time,
        // so only the newest past ride can have ended since the last session. A ride the driver cancelled
        // isn't reported, as they chose it.
        if let session,
           let endedRide = newSession.pastRides.first,
           endedRide.id != session.pastRides.first?.id,
           endedRide.cancelledBy == .rider {
            // The cancellation explains more than any error showing, including a step that failed because of it.
            alert = .riderCancelled(endedRide)
        }
        // An offer that ends as a ride starts, such as one declined by claiming a ride from the list, was answered
        // by the driver's choice.
        if let offer = session?.pendingOffer,
           newSession.pendingOffer?.id != offer.id,
           offer.id != answeredOfferID,
           newSession.activeRide == nil {
            unansweredOfferID = offer.id
        }
        // An error is about an earlier action, so it could seem to describe a new offer. A claim's conflict says
        // the rider is no longer waiting, which can't be mistaken for one about an offer, so it stays.
        if let offer = newSession.pendingOffer,
           offer.id != session?.pendingOffer?.id,
           case .error(let error) = alert,
           error != .rideNoLongerWaiting {
            alert = nil
        }
        session = newSession
    }

    func goOnline() async {
        await perform { () async throws(RideServiceError) in
            try await service.goOnline()
        }
    }

    func goOffline() async {
        await perform { () async throws(RideServiceError) in
            try await service.goOffline()
        }
    }

    /// Accepts the offer the driver is looking at.
    ///
    /// This takes an ID rather than using the current offer, because the offer can change between
    /// the driver seeing it and the tap being handled, and a driver must never take a ride they didn't review.
    func acceptOffer(id: RideOffer.ID) async {
        await perform { () async throws(RideServiceError) in
            try await respond(to: id) { () async throws(RideServiceError) in
                try await service.acceptOffer(id: id)
            }
        }
    }

    /// Declines the offer the driver is looking at.
    func declineOffer(id: RideOffer.ID) async {
        await perform { () async throws(RideServiceError) in
            try await respond(to: id) { () async throws(RideServiceError) in
                try await service.declineOffer(id: id)
            }
        }
    }

    /// Records that the driver reached the pickup for the ride they're looking at.
    ///
    /// Like ``acceptOffer(id:)``, the ride steps take the ID of the ride on screen, so a tap can't apply
    /// to a different ride.
    func markArrived(rideID: Ride.ID) async {
        await perform { () async throws(RideServiceError) in
            try await service.markArrived(rideID: rideID)
        }
    }

    func startTrip(rideID: Ride.ID) async {
        await perform { () async throws(RideServiceError) in
            try await service.startTrip(rideID: rideID)
        }
    }

    func completeTrip(rideID: Ride.ID) async {
        await perform { () async throws(RideServiceError) in
            try await service.completeTrip(rideID: rideID)
        }
    }

    /// Takes a ride from the waiting list, which the driver chose over waiting for an offer.
    ///
    /// The service declines a pending offer, as the driver has chosen another ride. That offer ends as the ride
    /// starts, so ``apply(_:)`` doesn't announce it as one left without a response.
    func claimRide(rideID: Ride.ID) async {
        await perform { () async throws(RideServiceError) in
            try await service.claimRide(rideID: rideID)
        }
    }

    /// Cancels the ride the driver is looking at, after they've confirmed it.
    func cancelRide(rideID: Ride.ID) async {
        await perform { () async throws(RideServiceError) in
            // Set inside the request, so a cancellation that `perform` drops doesn't show as in progress.
            isCancellingRide = true
            defer { isCancellingRide = false }
            return try await service.cancelRide(rideID: rideID)
        }
    }

    /// Sends a response to an offer, marking it as answered unless the response fails.
    ///
    /// The mark is set before the request, because the session that removes the offer can arrive through the
    /// stream before the request returns.
    private func respond(
        to offerID: RideOffer.ID,
        with request: () async throws(RideServiceError) -> DriverSession
    ) async throws(RideServiceError) -> DriverSession {
        answeredOfferID = offerID
        do {
            return try await request()
        } catch {
            // The driver's response didn't take effect, so the offer can still end unanswered.
            answeredOfferID = nil
            throw error
        }
    }

    /// Runs one request at a time, so a double tap can't send the same action twice.
    ///
    /// Any other action sent during a request is also dropped, without an error. Views must disable their
    /// controls while ``isPerformingAction`` is true, so that a driver's tap is never silently ignored.
    private func perform(_ request: () async throws(RideServiceError) -> DriverSession) async {
        guard isPerformingAction == false else {
            return
        }
        isPerformingAction = true
        let offerIDBefore = session?.pendingOffer?.id
        // A new attempt makes an earlier error out of date.
        if case .error = alert {
            alert = nil
        }
        defer { isPerformingAction = false }

        do {
            apply(try await request())
        } catch {
            // An error is about an earlier action, so if a new offer arrived during the request, it could seem to
            // describe that offer instead. A claim's conflict can't, as above.
            if let offerID = session?.pendingOffer?.id, offerID != offerIDBefore, error != .rideNoLongerWaiting {
                return
            }
            show(error)
        }
    }

    /// Shows an error, unless a rider cancellation already explains what happened.
    private func show(_ error: RideServiceError) {
        if case .riderCancelled = alert {
            return
        }
        // A step tapped as the rider cancelled fails because the ride ended. The cancellation explains that,
        // even if the driver has already dismissed it.
        if error == .rideNoLongerAvailable,
           session?.activeRide == nil,
           session?.pastRides.first?.cancelledBy == .rider {
            return
        }
        alert = .error(error)
    }
}
