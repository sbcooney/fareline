extension DriverSession {
    /// Returns this session with ride steps queued offline applied to its current ride, by the domain's own rules.
    ///
    /// A step that no longer applies is skipped: during replay, one the service has just confirmed, whose session can
    /// arrive before the step leaves the queue. Replay still sends every step, and the service's answer decides.
    /// Steps for another ride are skipped too, so a ride the rider has since cancelled shows as the service has it.
    func applying(_ steps: [PendingRideStep]) -> DriverSession {
        guard steps.isEmpty == false, var ride = activeRide else {
            return self
        }
        for step in steps where step.rideID == ride.id {
            try? ride.apply(step.event)
        }
        var driver = driver
        var activeRide: Ride? = ride
        var pastRides = pastRides
        if ride.status == .completed || ride.status == .cancelled {
            // The ride ended offline, so it moves to the driver's history, and they're free again, as the service
            // will record once the steps are sent.
            try? driver.apply(.rideEnded)
            activeRide = nil
            pastRides.insert(ride, at: 0)
        }
        return DriverSession(
            version: version,
            driver: driver,
            pendingOffer: pendingOffer,
            activeRide: activeRide,
            pastRides: pastRides,
            waitingRides: waitingRides
        )
    }
}
