import Foundation

/// The fixed data used by `MockRideService`.
enum MockRideData {
    /// The driver using the app.
    static let driver = Driver(
        id: UUID(),
        name: PersonNameComponents(givenName: "Sam", familyName: "Rivera")
    )

    private static let templates = [
        makeTemplate(
            givenName: "Ada",
            familyName: "Lovelace",
            pickup: Place(name: "Union Station", address: "50 Massachusetts Ave NE"),
            dropoff: Place(name: "National Mall", address: "900 Ohio Dr SW"),
            cents: 1840
        ),
        makeTemplate(
            givenName: "Alan",
            familyName: "Turing",
            pickup: Place(name: "Dupont Circle", address: "1 Dupont Cir NW"),
            dropoff: Place(name: "Reagan National Airport", address: "2401 Smith Blvd"),
            cents: 3225
        ),
        makeTemplate(
            givenName: "Katherine",
            familyName: "Johnson",
            pickup: Place(name: "Georgetown Waterfront", address: "3303 Water St NW"),
            dropoff: Place(name: "Capitol Hill", address: "101 Independence Ave SE"),
            cents: 2675
        )
    ]

    /// Creates a new ride from a repeating list, so a demo never runs out of offers.
    static func makeRide(sequence: Int, requestedAt: Date) -> Ride {
        let template = templates[sequence % templates.count]
        return Ride(
            id: UUID(),
            rider: template.rider,
            pickup: template.pickup,
            dropoff: template.dropoff,
            fare: template.fare,
            requestedAt: requestedAt
        )
    }

    private static func makeTemplate(
        givenName: String,
        familyName: String,
        pickup: Place,
        dropoff: Place,
        cents: Int
    ) -> Ride {
        Ride(
            id: UUID(),
            rider: Rider(id: UUID(), name: PersonNameComponents(givenName: givenName, familyName: familyName)),
            pickup: pickup,
            dropoff: dropoff,
            fare: Fare(amount: Decimal(cents) / 100, currencyCode: "USD"),
            requestedAt: .distantPast
        )
    }
}
