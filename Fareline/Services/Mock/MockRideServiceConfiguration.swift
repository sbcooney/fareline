import Foundation

/// Settings that control how `MockRideService` behaves.
struct MockRideServiceConfiguration: Sendable {
    /// How long an available driver waits for each offer, or `nil` to create offers only on request.
    var offerDelay: TimeInterval?

    /// How long a driver has to respond to an offer.
    var offerLifetime: TimeInterval

    /// How long each request takes, to imitate a network.
    var responseDelay: TimeInterval

    /// How often, while the driver is online, another driver passes on a new request and it joins the waiting
    /// list, or `nil` for never.
    var passedOverInterval: TimeInterval?

    /// The most rides the waiting list holds before other drivers stop passing on requests.
    var maximumWaitingRides = 6

    /// Settings that make the app's flow easy to demonstrate.
    static let demo = MockRideServiceConfiguration(
        offerDelay: 5,
        offerLifetime: 30,
        responseDelay: 0.4,
        passedOverInterval: 20
    )
}
