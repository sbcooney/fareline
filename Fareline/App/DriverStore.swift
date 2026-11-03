import Observation

/// The app's single source of truth, and the one path for every user action.
///
/// Views read ``session`` and call intent methods such as ``acceptOffer(id:)``. The store doesn't apply
/// business rules itself. It sends requests to the service and replaces its state with the result, so
/// the app and the service can't disagree. Keeping all actions here also gives offline support one
/// place to queue them.
@MainActor
@Observable
final class DriverStore {
    /// The latest session, or `nil` until the first one arrives.
    private(set) var session: DriverSession?

    /// Whether a request is in progress. Views use this to show progress and prevent repeat taps.
    private(set) var isPerformingAction = false

    /// The most recent failed action, if the driver hasn't dismissed it.
    private(set) var lastError: RideServiceError?

    /// Whether an error is waiting to be shown. Setting this to `false` dismisses the error.
    var isShowingError: Bool {
        get { lastError != nil }
        set {
            if newValue == false {
                dismissError()
            }
        }
    }

    /// The driver's ride that the rider cancelled, until the driver has seen it.
    private(set) var cancelledRide: Ride?

    /// Whether a cancelled ride is waiting to be shown. Setting this to `false` dismisses it.
    var isShowingCancelledRide: Bool {
        get { cancelledRide != nil }
        set {
            if newValue == false {
                dismissCancelledRide()
            }
        }
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
        // A newly cancelled ride is reported even if the session where it was active was skipped. The first
        // session is ignored, as its past rides are history rather than news. A driver has one ride at a time,
        // so only the newest past ride can have ended since the last session.
        if let session,
           let endedRide = newSession.pastRides.first,
           endedRide.id != session.pastRides.first?.id,
           endedRide.status == .cancelled {
            cancelledRide = endedRide
            // A step the driver tapped as the rider cancelled fails, and the cancellation already explains why.
            if lastError == .rideNoLongerAvailable {
                lastError = nil
            }
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
            try await service.acceptOffer(id: id)
        }
    }

    /// Declines the offer the driver is looking at.
    func declineOffer(id: RideOffer.ID) async {
        await perform { () async throws(RideServiceError) in
            try await service.declineOffer(id: id)
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

    /// Clears the most recent error once the driver has seen it.
    func dismissError() {
        lastError = nil
    }

    /// Clears the cancelled ride once the driver has seen it.
    func dismissCancelledRide() {
        cancelledRide = nil
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
        lastError = nil
        defer { isPerformingAction = false }

        do {
            apply(try await request())
        } catch .rideNoLongerAvailable where cancelledRide != nil {
            // The cancellation already explains why the step failed.
        } catch {
            lastError = error
        }
    }
}
