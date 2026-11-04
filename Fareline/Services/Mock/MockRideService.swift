import Foundation

// Parts with rules of their own are separate types: `WaitingList`, `SubscriberList`, and `PastRideStore`. What remains
// changes the ride, driver, and offer together on one actor, which is what makes each request atomic. Splitting it
// further would mean exposing that state to the rest of the module, as Swift's `private` doesn't cross files.
// swiftlint:disable file_length type_body_length

/// An in-memory stand-in for a backend, including its role in deciding who gets offered which ride.
///
/// It's named for rides rather than the driver because it plays the whole backend, riders included. It serves one
/// implied driver, so a rider app would add a rider-facing type over the same state rather than a second
/// conformance here.
///
/// Each request has at most one suspension point, at the start, for the simulated network delay. All state
/// is read and changed after that with no further `await`, so the actor's serial execution makes each
/// request atomic. This matters because actors can run other work during an `await`.
///
/// Methods beyond ``DriverService``, such as ``simulateRideCancelled(id:)``, imitate things that happen
/// elsewhere in a real system, such as a rider cancelling.
actor MockRideService: DriverService {
    private let configuration: MockRideServiceConfiguration
    private let timeSource: any TimeSource
    private let pastRideStore: PastRideStore?

    private var driver: Driver
    private var rides: [Ride.ID: Ride] = [:]
    private var pendingOffer: RideOffer?
    private var activeRideID: Ride.ID?
    private var pastRides: [Ride] = []

    private var waitingList = WaitingList()

    private var version = 0
    private var rideSequence = 0
    private var nextFailure: RideServiceError?
    private var sessionSubscribers = SubscriberList<DriverSession>()
    private var isConnected = true
    private var connectionSubscribers = SubscriberList<Bool>()
    private var nextOfferTask: Task<Void, Never>?
    private var expiryTask: Task<Void, Never>?
    private var riderCancellationTask: Task<Void, Never>?
    private var passedOverTask: Task<Void, Never>?

    /// - Parameters:
    ///   - pastRideStore: Where past rides are saved, or `nil` to keep them in memory only, as tests and previews
    ///     do.
    ///   - waitingRides: Rides that other drivers have already passed on, which start in the waiting list.
    init(
        configuration: MockRideServiceConfiguration = .demo,
        timeSource: any TimeSource = SystemTimeSource(),
        driver: Driver = MockRideData.driver,
        pastRideStore: PastRideStore? = nil,
        waitingRides: [Ride] = []
    ) {
        self.configuration = configuration
        self.timeSource = timeSource
        self.driver = driver
        self.pastRideStore = pastRideStore
        pastRides = pastRideStore?.load() ?? []
        for ride in waitingRides {
            rides[ride.id] = ride
            waitingList.add(ride.id)
        }
    }

    deinit {
        nextOfferTask?.cancel()
        expiryTask?.cancel()
        riderCancellationTask?.cancel()
        passedOverTask?.cancel()
        sessionSubscribers.finishAll()
        connectionSubscribers.finishAll()
    }

    // MARK: - DriverService

    func sessionUpdates() -> AsyncStream<DriverSession> {
        // A driver who's offline can't receive anything, so the session waits for the connection.
        sessionSubscribers.add(startingWith: isConnected ? session : nil) { [weak self] id in
            Task { await self?.removeSubscriber(id: id) }
        }
    }

    func connectionUpdates() -> AsyncStream<Bool> {
        connectionSubscribers.add(startingWith: isConnected) { [weak self] id in
            Task { await self?.removeSubscriber(id: id) }
        }
    }

    func goOnline() async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        try updateDriver(.wentOnline)
        scheduleNextOffer()
        schedulePassedOverRequest()
        return publish()
    }

    func goOffline() async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        try updateDriver(.wentOffline)
        if let offer = pendingOffer {
            waitingList.add(offer.ride.id)
        }
        clearPendingOffer()
        nextOfferTask?.cancel()
        passedOverTask?.cancel()
        return publish()
    }

    func acceptOffer(id: RideOffer.ID) async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        expireOfferIfDue()
        guard var offer = pendingOffer, offer.id == id, var ride = rides[offer.ride.id] else {
            throw .offerNoLongerAvailable
        }
        var updatedDriver = driver

        // These change local copies, and state is assigned only once all three succeed, so a failure
        // partway through can't leave the offer, ride, and driver disagreeing. The ride is read from
        // `rides` rather than `offer.ride`, because the offer's copy may be out of date.
        do {
            try offer.accept(at: timeSource.now)
            try ride.apply(.driverAssigned(driverID: driver.id))
            try updatedDriver.apply(.rideAssigned)
        } catch {
            throw .offerNoLongerAvailable
        }

        clearPendingOffer()
        rides[ride.id] = ride
        driver = updatedDriver
        activeRideID = ride.id
        scheduleRiderCancellation(of: ride)
        return publish()
    }

    func declineOffer(id: RideOffer.ID) async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        expireOfferIfDue()

        // An offer that has already ended gives the driver the outcome they wanted, so this isn't a failure.
        guard var offer = pendingOffer, offer.id == id else {
            return session
        }
        do {
            try offer.decline(at: timeSource.now)
        } catch {
            throw .offerNoLongerAvailable
        }

        // The ride stays awaiting a driver, and joins the list, as another driver could still take it.
        waitingList.add(offer.ride.id)
        clearPendingOffer()
        scheduleNextOffer()
        return publish()
    }

    func claimRide(rideID: Ride.ID) async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        guard driver.availability == .available else {
            throw .actionNotAllowed
        }
        if let ride = rides[rideID], MockRideData.isTakenByAnotherDriverWhenClaimed(ride) {
            // The demo's conflict case: another driver's request arrived first. The session reports the change, so
            // the driver's list drops the ride as they're told why.
            try? updateRide(id: rideID, with: .driverAssigned(driverID: UUID()))
            publish()
            throw .rideNoLongerWaiting
        }
        guard waitingList.hasListed(rideID), var ride = rides[rideID] else {
            throw .rideNoLongerWaiting
        }
        var updatedDriver = driver

        // As with accepting, local copies change first, so a failure can't leave the ride and driver disagreeing.
        do {
            try ride.apply(.driverAssigned(driverID: driver.id))
            try updatedDriver.apply(.rideAssigned)
        } catch {
            throw .rideNoLongerWaiting
        }

        // The driver chose another ride, so a pending offer is declined, and its ride joins the list.
        if let offer = pendingOffer {
            waitingList.add(offer.ride.id)
            clearPendingOffer()
        }
        nextOfferTask?.cancel()
        rides[ride.id] = ride
        driver = updatedDriver
        activeRideID = ride.id
        scheduleRiderCancellation(of: ride)
        return publish()
    }

    func markArrived(rideID: Ride.ID) async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        try updateActiveRide(id: rideID, with: .driverArrived)
        return publish()
    }

    func startTrip(rideID: Ride.ID) async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        try updateActiveRide(id: rideID, with: .tripStarted)
        riderCancellationTask?.cancel()
        return publish()
    }

    func completeTrip(rideID: Ride.ID, at date: Date) async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        // The driver's time is trusted, as a step queued offline happened before it was sent.
        try updateActiveRide(id: rideID, with: .tripCompleted(date: date))
        endActiveRide()
        scheduleNextOffer()
        return publish()
    }

    func cancelRide(rideID: Ride.ID, at date: Date) async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        let rideBefore = rides[rideID]
        // If the rider cancelled first, the ride is no longer active, so this fails rather than changing who
        // cancelled. Ending the ride also stops the rider's own scheduled cancellation.
        try updateActiveRide(id: rideID, with: .cancelled(by: .driver, date: date))
        // A rider who wasn't picked up yet still needs a ride. Once the trip has started, the ride is over.
        if let rideBefore, rideBefore.status != .inProgress {
            listNewRequest(for: rideBefore)
        }
        endActiveRide()
        scheduleNextOffer()
        return publish()
    }

    // MARK: - Private

    private var session: DriverSession {
        DriverSession(
            version: version,
            driver: driver,
            pendingOffer: pendingOffer,
            activeRide: activeRideID.flatMap { rides[$0] },
            pastRides: pastRides,
            waitingRides: waitingRides
        )
    }

    /// Passed-over rides that still need a driver, longest wait first.
    private var waitingRides: [Ride] {
        waitingList.rides(in: rides)
    }

    /// Imitates the network. This is the only suspension point in a request.
    private func beginRequest() async throws(RideServiceError) {
        // The failure is claimed before the delay, so it applies to this request and not one that arrives later.
        let failure = nextFailure
        nextFailure = nil

        if configuration.responseDelay > 0 {
            // Cancellation just ends the delay early. Like a request already sent to a server, it still completes.
            try? await timeSource.sleep(until: timeSource.now.addingTimeInterval(configuration.responseDelay))
        }
        if let failure {
            throw failure
        }
        // Checked after the delay, so a connection lost while a request is on its way fails it, as a real network
        // would. Nothing changes, so the driver's action can be sent again.
        if isConnected == false {
            throw .networkUnavailable
        }
    }

    private func updateDriver(_ event: DriverEvent) throws(RideServiceError) {
        do {
            try driver.apply(event)
        } catch {
            throw .actionNotAllowed
        }
    }

    private func updateRide(id: Ride.ID, with event: RideEvent) throws(RideServiceError) {
        guard var ride = rides[id] else {
            throw .rideNoLongerAvailable
        }
        do {
            try ride.apply(event)
        } catch {
            throw .rideNoLongerAvailable
        }
        rides[id] = ride
    }

    private func updateActiveRide(id: Ride.ID, with event: RideEvent) throws(RideServiceError) {
        guard activeRideID == id else {
            throw .rideNoLongerAvailable
        }
        do {
            try updateRide(id: id, with: event)
        } catch {
            // The ride is still current here, so the problem is the step, such as a repeated tap.
            throw .actionNotAllowed
        }
    }

    /// Moves the active ride, which has already completed or been cancelled, into the driver's past rides.
    private func endActiveRide() {
        if let ride = activeRideID.flatMap({ rides[$0] }) {
            pastRides.insert(ride, at: 0)
            // If saving fails, the store logs it. The ride still appears in this session, and is only missing
            // after a relaunch.
            try? pastRideStore?.save(pastRides)
        }
        activeRideID = nil
        riderCancellationTask?.cancel()
        // A driver with an active ride is always `onRide`, so this transition can't fail.
        try? driver.apply(.rideEnded)
    }

    private func clearPendingOffer() {
        pendingOffer = nil
        expiryTask?.cancel()
    }

    private func withdrawOffer(forRideID id: Ride.ID) {
        guard pendingOffer?.ride.id == id else {
            return
        }
        clearPendingOffer()
        scheduleNextOffer()
    }

    /// Adds a new request to the waiting list for a rider whose driver cancelled before picking them up.
    ///
    /// It keeps the original request time, as the rider has been waiting since then.
    private func listNewRequest(for ride: Ride) {
        let request = Ride(
            id: UUID(),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: ride.requestedAt
        )
        rides[request.id] = request
        waitingList.add(request.id)
    }

    /// Sends the current session to all subscribers.
    @discardableResult
    private func publish() -> DriverSession {
        version += 1
        let session = session
        // While disconnected, changes still happen, but the driver hears about them only when the connection returns.
        if isConnected {
            sessionSubscribers.send(session)
        }
        return session
    }

    /// Removes a subscriber whose stream ended. IDs are unique, so this doesn't need to know which stream it was.
    private func removeSubscriber(id: UUID) {
        sessionSubscribers.remove(id: id)
        connectionSubscribers.remove(id: id)
    }

    /// Runs work on the actor once the given time arrives, unless the returned task is cancelled first.
    ///
    /// The work is checked on the actor, not before it gets there: a task can be cancelled after its sleep ends but
    /// before its turn on the actor, so work that must not run late checks `Task.isCancelled` itself.
    private func runTask(
        at date: Date,
        _ work: @escaping @Sendable (isolated MockRideService) async -> Void
    ) -> Task<Void, Never> {
        let timeSource = timeSource
        return Task { [weak self] in
            do {
                try await timeSource.sleep(until: date)
            } catch {
                return
            }
            guard let self else {
                return
            }
            await work(self)
        }
    }

    private func scheduleNextOffer() {
        nextOfferTask?.cancel()
        guard let delay = configuration.offerDelay else {
            return
        }
        nextOfferTask = runTask(at: timeSource.now.addingTimeInterval(delay)) { service in
            service.offerNextRide()
        }
    }

    private func offerNextRide() {
        // Running after a cancellation would create an offer ahead of its replacement timer. See `runTask(at:_:)`.
        guard Task.isCancelled == false, driver.availability == .available, pendingOffer == nil else {
            return
        }
        guard let ride = makeNextRequest() else {
            // Every rider already has a ride waiting, so try again once one may have left the list.
            scheduleNextOffer()
            return
        }
        rides[ride.id] = ride
        // The guard above and the new ride's status mean the offer can't be refused.
        try? offerRide(id: ride.id)
    }

    /// Returns a new request from the next repeating rider who doesn't already have a ride waiting or in progress,
    /// or `nil` if every one of them does, so the same person never asks for two rides at once.
    private func makeNextRequest() -> Ride? {
        let busyRiderIDs = Set(
            rides.values
                .filter { $0.status == .awaitingDriver || $0.id == activeRideID }
                .map(\.rider.id)
        )
        for _ in 0..<MockRideData.repeatingRiderCount {
            let ride = MockRideData.makeRide(sequence: rideSequence, requestedAt: timeSource.now)
            rideSequence += 1
            if busyRiderIDs.contains(ride.rider.id) == false {
                return ride
            }
        }
        return nil
    }

    /// Has another driver pass on a new request after the configured interval, and repeats while the driver is
    /// online.
    private func schedulePassedOverRequest() {
        passedOverTask?.cancel()
        guard let interval = configuration.passedOverInterval else {
            return
        }
        passedOverTask = runTask(at: timeSource.now.addingTimeInterval(interval)) { service in
            service.addPassedOverRequest()
        }
    }

    private func addPassedOverRequest() {
        // Going offline can cancel this task after its sleep ends. See `runTask(at:_:)`.
        guard Task.isCancelled == false, driver.availability != .offline else {
            return
        }
        schedulePassedOverRequest()
        guard waitingRides.count < configuration.maximumWaitingRides else {
            return
        }
        guard let ride = makeNextRequest() else {
            return
        }
        rides[ride.id] = ride
        waitingList.add(ride.id)
        publish()
    }

    private func scheduleExpiry(of offer: RideOffer) {
        expiryTask?.cancel()
        let id = offer.id
        expiryTask = runTask(at: offer.expiresAt) { service in
            service.expireOffer(id: id)
        }
    }

    /// Ends an offer whose time is up, in case a response arrives before the expiry timer has run.
    private func expireOfferIfDue() {
        guard let offer = pendingOffer, timeSource.now >= offer.expiresAt else {
            return
        }
        expireOffer(id: offer.id)
    }

    private func expireOffer(id: RideOffer.ID) {
        guard var offer = pendingOffer, offer.id == id else {
            return
        }
        do {
            try offer.expire(at: timeSource.now)
        } catch {
            // The wait can end early if the system clock changes. Without another timer, the offer would stay
            // pending forever, accepting no responses and blocking new offers.
            scheduleExpiry(of: offer)
            return
        }
        waitingList.add(offer.ride.id)
        clearPendingOffer()
        scheduleNextOffer()
        publish()
    }
}

// MARK: - Simulating the rest of the system

extension MockRideService {
    /// Imitates losing or regaining the driver's connection.
    ///
    /// While disconnected, requests fail with ``RideServiceError/networkUnavailable`` and change nothing, and no
    /// sessions are sent. The mock's own world keeps running, so offers still expire and riders still cancel. On
    /// reconnecting, the latest session is sent.
    func setConnected(_ connected: Bool) {
        guard connected != isConnected else {
            return
        }
        isConnected = connected
        connectionSubscribers.send(connected)
        if connected {
            sessionSubscribers.send(session)
        }
    }

    /// Makes the next request fail with the given error, leaving all state unchanged.
    func failNextRequest(with error: RideServiceError) {
        nextFailure = error
    }

    /// Returns the current state of a ride.
    func ride(id: Ride.ID) -> Ride? {
        rides[id]
    }

    /// Adds a ride that needs a driver.
    func addRide(_ ride: Ride) {
        rides[ride.id] = ride
    }

    /// Offers a ride to the driver.
    ///
    /// This is the only way an offer is created, which enforces three rules. A ride must be awaiting a driver,
    /// it's offered to one driver at a time, and a ride in the waiting list isn't offered again, as the driver can
    /// already see and take it. The second rule holds because this mock has a single driver with a single pending
    /// offer. A real backend would have to track offers per ride.
    ///
    /// - Throws: ``RideServiceError/actionNotAllowed`` if the ride can't be offered right now.
    func offerRide(id: Ride.ID) throws(RideServiceError) {
        guard driver.availability == .available,
              pendingOffer == nil,
              waitingList.hasListed(id) == false,
              let ride = rides[id],
              ride.status == .awaitingDriver else {
            throw .actionNotAllowed
        }

        let offer = RideOffer(
            id: UUID(),
            ride: ride,
            driverID: driver.id,
            expiresAt: timeSource.now.addingTimeInterval(configuration.offerLifetime)
        )
        pendingOffer = offer
        nextOfferTask?.cancel()
        scheduleExpiry(of: offer)
        publish()
    }

    /// Imitates a rider cancelling. The driver's current ride moves to their past rides, and they become available.
    ///
    /// A late or duplicate cancellation has no effect on the driver, because a ride that has already ended
    /// fails to transition, and only the current ride can end the driver's `onRide` state.
    ///
    /// - Throws: ``RideServiceError/rideNoLongerAvailable`` if the ride can't be cancelled.
    func simulateRideCancelled(id: Ride.ID) throws(RideServiceError) {
        try updateRide(id: id, with: .cancelled(by: .rider, date: timeSource.now))
        if activeRideID == id {
            endActiveRide()
            scheduleNextOffer()
        }
        withdrawOffer(forRideID: id)
        publish()
    }

    /// Makes the rider cancel after a delay, if the mock data says this rider does.
    private func scheduleRiderCancellation(of ride: Ride) {
        guard let delay = MockRideData.riderCancellationDelay(for: ride) else {
            return
        }
        let id = ride.id
        riderCancellationTask = runTask(at: timeSource.now.addingTimeInterval(delay)) { service in
            // Starting the trip cancels this task, and the service rejects a cancellation that runs anyway.
            try? service.simulateRideCancelled(id: id)
        }
    }

    /// Imitates another driver taking a ride.
    ///
    /// - Throws: ``RideServiceError/rideNoLongerAvailable`` if the ride can't be taken.
    func simulateRideTaken(id: Ride.ID, byDriverID driverID: Driver.ID) throws(RideServiceError) {
        try updateRide(id: id, with: .driverAssigned(driverID: driverID))
        withdrawOffer(forRideID: id)
        publish()
    }
}
