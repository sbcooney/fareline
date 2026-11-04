import Testing
@testable import Fareline

/// Covers where the driver ends up as offers and rides come and go.
struct AppNavigationTests {
    private var navigation = AppNavigation()

    // MARK: - Offers opened from the bar

    @Test mutating func openingAnOfferReturnsToTheRootScreen() {
        navigation.open(.pastRides)

        navigation.openOffer()

        #expect(navigation.path.isEmpty)
    }

    @Test mutating func offerEndingWithoutARidePutsBackTheScreensTheDriverLeft() {
        navigation.open(.pastRides)
        navigation.open(.pastRide(TestFixtures.ride().id))
        navigation.openOffer()

        navigation.offerEnded(rideStarted: false)

        #expect(navigation.path == [.pastRides, .pastRide(TestFixtures.ride().id)])
    }

    @Test mutating func offerEndingWithARideStaysOnTheRide() {
        navigation.open(.waitingRiders)
        navigation.openOffer()
        navigation.rideStarted()

        navigation.offerEnded(rideStarted: true)

        #expect(navigation.path.isEmpty)
    }

    @Test mutating func offerEndingBeforeItsRideStartsStaysOnTheRoot() {
        navigation.open(.waitingRiders)
        navigation.openOffer()

        // The session's changes can be handled in either order.
        navigation.offerEnded(rideStarted: true)
        navigation.rideStarted()

        #expect(navigation.path.isEmpty)
    }

    @Test mutating func offerEndingOnTheRootScreenChangesNothing() {
        navigation.offerEnded(rideStarted: false)

        #expect(navigation.path.isEmpty)
    }

    @Test mutating func savedScreensArePutBackOnlyOnce() {
        navigation.open(.pastRides)
        navigation.openOffer()
        navigation.offerEnded(rideStarted: false)
        navigation.path.removeAll()

        // A later offer that arrived on the root screen, and ends, has nothing to put back.
        navigation.offerEnded(rideStarted: false)

        #expect(navigation.path.isEmpty)
    }

    // MARK: - Rides taken from Waiting Riders

    @Test mutating func rideStartingClearsThePath() {
        navigation.open(.pastRides)

        navigation.rideStarted()

        #expect(navigation.path.isEmpty)
    }

    @Test mutating func cancellingARideTakenFromWaitingRidersReturnsThere() {
        navigation.open(.waitingRiders)
        navigation.rideStarted()

        navigation.rideEnded(cancelledByDriver: true)

        #expect(navigation.path == [.waitingRiders])
    }

    @Test mutating func riderCancellingOrCompletingReturnsToTheHomeScreen() {
        navigation.open(.waitingRiders)
        navigation.rideStarted()

        navigation.rideEnded(cancelledByDriver: false)

        #expect(navigation.path.isEmpty)
    }

    @Test mutating func cancellingAfterTheTripStartedReturnsToTheHomeScreen() {
        navigation.open(.waitingRiders)
        navigation.rideStarted()
        navigation.tripStarted()

        navigation.rideEnded(cancelledByDriver: true)

        #expect(navigation.path.isEmpty)
    }

    @Test mutating func rideFromAnotherScreenDoesntReturnToWaitingRiders() {
        navigation.open(.pastRides)
        navigation.rideStarted()

        navigation.rideEnded(cancelledByDriver: true)

        #expect(navigation.path.isEmpty)
    }

    @Test mutating func onlyTheRideTakenFromWaitingRidersReturnsThere() {
        navigation.open(.waitingRiders)
        navigation.rideStarted()
        navigation.rideEnded(cancelledByDriver: true)
        navigation.path.removeAll()
        navigation.rideStarted()

        navigation.rideEnded(cancelledByDriver: true)

        #expect(navigation.path.isEmpty)
    }
}
