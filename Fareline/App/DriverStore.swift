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

    func markArrived() async {
        guard let id = session?.activeRide?.id else {
            return
        }
        await perform { () async throws(RideServiceError) in
            try await service.markArrived(rideID: id)
        }
    }

    func startTrip() async {
        guard let id = session?.activeRide?.id else {
            return
        }
        await perform { () async throws(RideServiceError) in
            try await service.startTrip(rideID: id)
        }
    }

    func completeTrip() async {
        guard let id = session?.activeRide?.id else {
            return
        }
        await perform { () async throws(RideServiceError) in
            try await service.completeTrip(rideID: id)
        }
    }

    /// Clears the most recent error once the driver has seen it.
    func dismissError() {
        lastError = nil
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
        } catch {
            lastError = error
        }
    }
}
