import Foundation
@testable import Fareline

/// Fixed sample values, so tests are repeatable and independent of the system clock.
enum TestFixtures {
    static let driverID = UUID(testValue: 1)
    static let date = Date(timeIntervalSinceReferenceDate: 800_000_000)

    static let rideEvents: [RideEvent] = [
        .driverAssigned(driverID: driverID),
        .driverArrived,
        .tripStarted,
        .tripCompleted(date: date),
        .cancelled
    ]

    static func ride() -> Ride {
        Ride(
            id: UUID(testValue: 2),
            rider: Rider(
                id: UUID(testValue: 3),
                name: PersonNameComponents(givenName: "Ada", familyName: "Lovelace")
            ),
            pickup: Place(name: "Union Station", address: "50 Massachusetts Ave NE"),
            dropoff: Place(name: "National Mall", address: "900 Ohio Dr SW"),
            fare: Fare(amount: Decimal(1840) / 100, currencyCode: "USD"),
            requestedAt: date
        )
    }

    static func offer() -> RideOffer {
        RideOffer(
            id: UUID(testValue: 4),
            ride: ride(),
            driverID: driverID,
            expiresAt: date.addingTimeInterval(30)
        )
    }
}

extension UUID {
    /// Creates a fixed identifier whose last byte is the given value.
    init(testValue: UInt8) {
        self.init(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, testValue))
    }
}
