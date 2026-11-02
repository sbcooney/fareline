import Foundation

/// An in-memory stand-in for a backend, including its role in deciding who gets offered which ride.
///
/// Each request has at most one suspension point, at the start, for the simulated network delay. All state
/// is read and changed after that with no further `await`, so the actor's serial execution makes each
/// request atomic. This matters because actors can run other work during an `await`.
///
/// Methods beyond ``RideService``, such as ``simulateRideCancelled(id:)``, imitate things that happen
/// elsewhere in a real system, such as a rider cancelling.
actor MockRideService: RideService {
    private let configuration: MockRideServiceConfiguration
    private let timeSource: any TimeSource

    private var driver: Driver
    private var rides: [Ride.ID: Ride] = [:]
    private var pendingOffer: RideOffer?
    private var activeRideID: Ride.ID?
    private var completedRides: [Ride] = []

    private var version = 0
    private var rideSequence = 0
    private var nextFailure: RideServiceError?
    private var subscribers: [UUID: AsyncStream<DriverSession>.Continuation] = [:]
    private var nextOfferTask: Task<Void, Never>?
    private var expiryTask: Task<Void, Never>?

    init(
        configuration: MockRideServiceConfiguration = .demo,
        timeSource: any TimeSource = SystemTimeSource(),
        driver: Driver = MockRideData.driver
    ) {
        self.configuration = configuration
        self.timeSource = timeSource
        self.driver = driver
    }

    deinit {
        nextOfferTask?.cancel()
        expiryTask?.cancel()
        subscribers.values.forEach { $0.finish() }
    }

    // MARK: - RideService

    func sessionUpdates() -> AsyncStream<DriverSession> {
        // Only the newest snapshot matters because each one is complete, so older unread ones can be dropped.
        let (stream, continuation) = AsyncStream.makeStream(
            of: DriverSession.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let id = UUID()
        subscribers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id: id) }
        }
        continuation.yield(session)
        return stream
    }

    func goOnline() async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        try updateDriver(.wentOnline)
        scheduleNextOffer()
        return publish()
    }

    func goOffline() async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        try updateDriver(.wentOffline)
        clearPendingOffer()
        nextOfferTask?.cancel()
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

        // The ride stays awaiting a driver, as another driver could still take it.
        clearPendingOffer()
        scheduleNextOffer()
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
        return publish()
    }

    func completeTrip(rideID: Ride.ID) async throws(RideServiceError) -> DriverSession {
        try await beginRequest()
        try updateActiveRide(id: rideID, with: .tripCompleted(date: timeSource.now))
        endActiveRide()
        if let ride = rides[rideID] {
            completedRides.insert(ride, at: 0)
        }
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
            completedRides: completedRides
        )
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

    private func endActiveRide() {
        activeRideID = nil
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

    /// Sends the current session to all subscribers.
    @discardableResult
    private func publish() -> DriverSession {
        version += 1
        let session = session
        subscribers.values.forEach { $0.yield(session) }
        return session
    }

    private func removeSubscriber(id: UUID) {
        subscribers[id] = nil
    }

    private func scheduleNextOffer() {
        nextOfferTask?.cancel()
        guard let delay = configuration.offerDelay else {
            return
        }
        let timeSource = timeSource
        let date = timeSource.now.addingTimeInterval(delay)
        nextOfferTask = Task { [weak self] in
            do {
                try await timeSource.sleep(until: date)
            } catch {
                return
            }
            await self?.offerNextRide()
        }
    }

    private func offerNextRide() {
        // This must be checked here, on the actor. A task can be cancelled after its sleep ends but before
        // it gets its turn on the actor, and running then would create an offer ahead of its replacement timer.
        guard Task.isCancelled == false, driver.availability == .available, pendingOffer == nil else {
            return
        }
        let ride = MockRideData.makeRide(sequence: rideSequence, requestedAt: timeSource.now)
        rideSequence += 1
        rides[ride.id] = ride
        // The guard above and the new ride's status mean the offer can't be refused.
        try? offerRide(id: ride.id)
    }

    private func scheduleExpiry(of offer: RideOffer) {
        expiryTask?.cancel()
        let timeSource = timeSource
        let id = offer.id
        let expiresAt = offer.expiresAt
        expiryTask = Task { [weak self] in
            do {
                try await timeSource.sleep(until: expiresAt)
            } catch {
                return
            }
            await self?.expireOffer(id: id)
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
        clearPendingOffer()
        scheduleNextOffer()
        publish()
    }
}

// MARK: - Simulating the rest of the system

extension MockRideService {
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
    /// This is the only way an offer is created, which enforces two rules. A ride must be awaiting a driver,
    /// and it's offered to one driver at a time. The second rule holds because this mock has a single
    /// driver with a single pending offer. A real backend would have to track offers per ride.
    ///
    /// - Throws: ``RideServiceError/actionNotAllowed`` if the ride can't be offered right now.
    func offerRide(id: Ride.ID) throws(RideServiceError) {
        guard driver.availability == .available,
              pendingOffer == nil,
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

    /// Imitates a rider cancelling. If this is the driver's current ride, the driver becomes available.
    ///
    /// A late or duplicate cancellation has no effect on the driver, because a ride that has already ended
    /// fails to transition, and only the current ride can end the driver's `onRide` state.
    ///
    /// - Throws: ``RideServiceError/rideNoLongerAvailable`` if the ride can't be cancelled.
    func simulateRideCancelled(id: Ride.ID) throws(RideServiceError) {
        try updateRide(id: id, with: .cancelled)
        if activeRideID == id {
            endActiveRide()
            scheduleNextOffer()
        }
        withdrawOffer(forRideID: id)
        publish()
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
