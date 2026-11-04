import Foundation
import Observation

/// The app's single source of truth, and the one path for every user action.
///
/// Views read ``session`` and call intent methods such as ``acceptOffer(id:)``. The model doesn't apply
/// business rules itself. It sends requests to the service and replaces its state with the result, so
/// the app and the service can't disagree. The one exception is offline: ride steps queue in
/// ``pendingSteps``, and the session on screen shows them by the domain's own transition rules until the service
/// confirms them.
@MainActor
@Observable
final class DriverModel {
    /// The latest session from the service, or `nil` until the first one arrives.
    private var receivedSession: DriverSession?

    /// Ride steps taken while offline, in order, waiting to be sent when the connection returns.
    private(set) var pendingSteps: [PendingRideStep] = []

    /// The session on screen: the latest from the service, with any queued steps applied on top, so the driver
    /// sees where they've got to. Without queued steps, it's the service's session as it is.
    var session: DriverSession? {
        receivedSession.map(showingPendingSteps)
    }

    /// Whether a request is in progress. Views use this to show progress and prevent repeat taps.
    private(set) var isPerformingAction = false

    /// Whether the request in progress is cancelling the driver's ride, so views show progress on the control
    /// the driver used rather than on the ride's next step.
    private(set) var isCancellingRide = false

    /// Whether the connection is down, as the service reports it. Nothing polls for this.
    private(set) var isOffline = false

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
        guard isPerformingAction == false,
              isOffline == false,
              let availability = session?.driver.availability else {
            return false
        }
        return availability != .onRide
    }

    private let service: any DriverService
    private let timeSource: any TimeSource

    /// - Parameter timeSource: Supplies the time a trip is completed or cancelled, so tests can control it.
    init(service: any DriverService, timeSource: any TimeSource = SystemTimeSource()) {
        self.service = service
        self.timeSource = timeSource
    }

    /// Receives session and connection updates until the calling task is cancelled.
    func start() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.receiveSessions() }
            group.addTask { await self.receiveConnectionChanges() }
        }
    }

    private func receiveSessions() async {
        for await session in await service.sessionUpdates() {
            apply(session)
        }
    }

    private func receiveConnectionChanges() async {
        for await isConnected in await service.connectionUpdates() {
            isOffline = isConnected == false
            if isConnected {
                // Changes that arrive meanwhile wait until the replay has finished, which keeps the order simple.
                await replayPendingSteps()
            }
        }
    }

    /// Updates the state, unless a newer session has already been applied.
    ///
    /// A request's result and a stream update travel separately, so they can arrive out of order.
    ///
    /// It compares against the service's last session, not the one on screen, so steps queued offline, such as a
    /// completed trip, aren't mistaken for news from the service.
    func apply(_ newSession: DriverSession) {
        let session = receivedSession
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
        receivedSession = newSession
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
    ///
    /// Offline, a ride step is queued and shown straight away. See ``pendingSteps``.
    func markArrived(rideID: Ride.ID) async {
        await takeStep(PendingRideStep(rideID: rideID, event: .driverArrived))
    }

    func startTrip(rideID: Ride.ID) async {
        await takeStep(PendingRideStep(rideID: rideID, event: .tripStarted))
    }

    func completeTrip(rideID: Ride.ID) async {
        await takeStep(PendingRideStep(rideID: rideID, event: .tripCompleted(date: timeSource.now)))
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

    /// Cancels the ride the driver is looking at, after they've confirmed it. Offline, it queues like a ride step,
    /// so a driver can end an unsafe trip without signal.
    func cancelRide(rideID: Ride.ID) async {
        let step = PendingRideStep(rideID: rideID, event: .cancelled(by: .driver, date: timeSource.now))
        guard isOffline == false else {
            queue(step)
            return
        }
        await perform { () async throws(RideServiceError) in
            // Set inside the request, so a cancellation that `perform` drops doesn't show as in progress.
            isCancellingRide = true
            defer { isCancellingRide = false }
            return try await send(step)
        }
    }

    /// Sends a ride step, or queues it while offline.
    private func takeStep(_ step: PendingRideStep) async {
        guard isOffline == false else {
            queue(step)
            return
        }
        await perform { () async throws(RideServiceError) in
            try await send(step)
        }
    }

    /// Queues a step taken offline, if it follows from the ride on screen, as the service would check online.
    private func queue(_ step: PendingRideStep) {
        guard var ride = session?.activeRide, ride.id == step.rideID else {
            show(.rideNoLongerAvailable)
            return
        }
        do {
            try ride.apply(step.event)
        } catch {
            show(.actionNotAllowed)
            return
        }
        pendingSteps.append(step)
    }

    private func send(_ step: PendingRideStep) async throws(RideServiceError) -> DriverSession {
        switch step.event {
        case .driverArrived:
            return try await service.markArrived(rideID: step.rideID)
        case .tripStarted:
            return try await service.startTrip(rideID: step.rideID)
        case .tripCompleted(let date):
            return try await service.completeTrip(rideID: step.rideID, at: date)
        case .cancelled(_, let date):
            return try await service.cancelRide(rideID: step.rideID, at: date)
        case .driverAssigned:
            // Not a ride step: a driver takes a ride by accepting or claiming it, which needs a live answer.
            throw .actionNotAllowed
        }
    }

    /// Sends the steps queued offline, in order, one request at a time.
    ///
    /// The service wins a conflict. If it refuses a step, the steps after it build on a ride that no longer exists
    /// as the driver saw it, so they're dropped, and the service's session stands.
    private func replayPendingSteps() async {
        guard pendingSteps.isEmpty == false, isPerformingAction == false else {
            return
        }
        isPerformingAction = true
        defer { isPerformingAction = false }

        while let step = pendingSteps.first {
            do {
                let newSession = try await send(step)
                pendingSteps.removeFirst()
                apply(newSession)
            } catch .networkUnavailable {
                // The connection dropped again, so the steps wait for the next reconnect.
                return
            } catch {
                pendingSteps.removeAll()
                // A rider's cancellation explains more, and arrives with the service's session, even if the driver
                // has already dismissed it, as `show(_:)` also checks.
                let riderCancelled = receivedSession?.activeRide == nil
                    && receivedSession?.pastRides.first?.cancelledBy == .rider
                if case .riderCancelled = alert {
                    return
                }
                if riderCancelled == false {
                    alert = .offlineStepsNotSent
                }
                return
            }
        }
    }

    /// Returns a session from the service with the queued steps applied to its current ride.
    ///
    /// A step that no longer applies is skipped: during replay, one the service has just confirmed, whose session can
    /// arrive before the step leaves the queue. Replay still sends every step, and the service's answer decides.
    /// Steps for another ride are skipped too, so a ride the rider has since cancelled shows as the service has it.
    private func showingPendingSteps(on received: DriverSession) -> DriverSession {
        guard pendingSteps.isEmpty == false, var ride = received.activeRide else {
            return received
        }
        for step in pendingSteps where step.rideID == ride.id {
            try? ride.apply(step.event)
        }
        var driver = received.driver
        var activeRide: Ride? = ride
        var pastRides = received.pastRides
        if ride.status == .completed || ride.status == .cancelled {
            // The ride ended offline, so it moves to the driver's history, and they're free again, as the service
            // will record once the steps are sent.
            try? driver.apply(.rideEnded)
            activeRide = nil
            pastRides.insert(ride, at: 0)
        }
        return DriverSession(
            version: received.version,
            driver: driver,
            pendingOffer: received.pendingOffer,
            activeRide: activeRide,
            pastRides: pastRides,
            waitingRides: received.waitingRides
        )
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
    /// Offline, nothing is sent: views disable these actions, as each needs a live answer.
    private func perform(_ request: () async throws(RideServiceError) -> DriverSession) async {
        guard isPerformingAction == false, isOffline == false else {
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
