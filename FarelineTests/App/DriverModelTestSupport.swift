import Foundation
@testable import Fareline

extension MockRideService {
    /// Returns a service for model tests, with no automatic offers and delays controlled by the test.
    static func forModelTests(time: ManualTimeSource, responseDelay: TimeInterval = 0) -> MockRideService {
        MockRideService(
            configuration: MockRideServiceConfiguration(
                offerDelay: nil,
                offerLifetime: 30,
                responseDelay: responseDelay
            ),
            timeSource: time,
            driver: Driver(
                id: TestFixtures.driverID,
                name: PersonNameComponents(givenName: "Grace", familyName: "Hopper")
            )
        )
    }
}

/// Waits for a condition on the model, without relying on delays.
@MainActor
func waitUntil(_ condition: @escaping @MainActor () -> Bool) async {
    for await isMet in Observations(condition) where isMet {
        return
    }
}
