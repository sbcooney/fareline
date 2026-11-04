/// Where the driver is in the app, and where they go as offers and rides come and go.
///
/// `RootView` holds this in its state and calls it as the session changes. It's a value type with no model or timing,
/// so every rule about where the driver ends up can be tested directly.
struct AppNavigation {
    /// The screens pushed on the root screen.
    var path: [AppDestination] = []

    /// The screens the driver was on when they opened an offer from the bar, to return to if it ends without a ride
    /// starting, such as Waiting Riders after a decline.
    private var pathBeforeOffer: [AppDestination]?

    /// Whether the current ride was taken from Waiting Riders and its trip hasn't started, so cancelling it returns
    /// the driver to the list they were choosing from.
    private var returnsToWaitingRiders = false

    mutating func open(_ destination: AppDestination) {
        path.append(destination)
    }

    /// Returns to the root screen, where a pending offer is shown, remembering the screens the driver left.
    mutating func openOffer() {
        pathBeforeOffer = path
        path.removeAll()
    }

    /// Puts back the screens the driver left to see an offer, once it ends without a ride starting: declined,
    /// expired, or withdrawn. An accepted offer starts a ride, which stays the root screen, whichever of the two the
    /// view handles first when they arrive in one session.
    mutating func offerEnded(rideStarted: Bool) {
        guard let savedPath = pathBeforeOffer else {
            return
        }
        pathBeforeOffer = nil
        if rideStarted == false {
            path = savedPath
        }
    }

    /// Makes a ride the root screen, as it has no bar like an offer does. A ride taken from Waiting Riders remembers
    /// it, so cancelling can return there.
    mutating func rideStarted() {
        returnsToWaitingRiders = path.last == .waitingRiders
        path.removeAll()
        // The ride replaces whatever the driver left, so a later offer ending has nothing to put back.
        pathBeforeOffer = nil
    }

    /// Once the rider is in the car, a cancelled ride is over rather than a reason to choose another.
    mutating func tripStarted() {
        returnsToWaitingRiders = false
    }

    /// Returns to Waiting Riders after the driver cancels a ride they took from it, before the trip started. A
    /// completed ride, or a rider's cancellation, ends on the home screen.
    mutating func rideEnded(cancelledByDriver: Bool) {
        if returnsToWaitingRiders, cancelledByDriver {
            path = [.waitingRiders]
        }
        returnsToWaitingRiders = false
    }
}
