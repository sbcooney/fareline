import Foundation

/// The fixed data used by `MockRideService`.
enum MockRideData {
    /// The driver using the app.
    ///
    /// The ID is fixed because saved past rides record their driver, and a new ID on each launch would
    /// orphan them.
    static let driver = Driver(
        id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
        name: PersonNameComponents(givenName: "Grace", familyName: "Hopper")
    )

    /// The parts of a ride that repeat each time it's offered.
    private struct Template {
        let rider: Rider
        let pickup: Place
        let dropoff: Place
        let fare: Fare

        /// How long after the driver accepts the ride the rider cancels, or `nil` if they don't.
        let riderCancelsAfter: TimeInterval?
    }

    private static let templates = [
        makeTemplate(
            givenName: "Ada",
            familyName: "Lovelace",
            pickup: Place(name: "Union Station", address: "50 Massachusetts Ave NE"),
            dropoff: Place(name: "National Mall", address: "900 Ohio Dr SW"),
            cents: 1840
        ),
        // Riders whose names describe what they do let a reviewer trigger behavior that the driver doesn't
        // control. Will Cancel cancels shortly after the driver accepts, unless the trip has already started.
        makeTemplate(
            givenName: "Will",
            familyName: "Cancel",
            pickup: Place(name: "Eastern Market", address: "225 7th St SE"),
            dropoff: Place(name: "The Wharf", address: "760 Maine Ave SW"),
            cents: 1490,
            riderCancelsAfter: 10
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

    /// Returns rides that other drivers have already passed on, so the demo's waiting list starts with riders who
    /// have waited several minutes.
    static func passedOverRides(at date: Date) -> [Ride] {
        // Riders that don't trigger demo events, waiting 9, 5, and 2 minutes.
        [(2, 540), (3, 300), (0, 120)].map { index, secondsWaited in
            let template = templates[index]
            return Ride(
                id: UUID(),
                rider: template.rider,
                pickup: template.pickup,
                dropoff: template.dropoff,
                fare: template.fare,
                requestedAt: date.addingTimeInterval(-TimeInterval(secondsWaited))
            )
        }
    }

    /// Returns how long after the driver accepts a ride its rider cancels, or `nil` if they don't.
    static func riderCancellationDelay(for ride: Ride) -> TimeInterval? {
        templates.first { $0.rider.id == ride.rider.id }?.riderCancelsAfter
    }

    private static func makeTemplate(
        givenName: String,
        familyName: String,
        pickup: Place,
        dropoff: Place,
        cents: Int,
        riderCancelsAfter: TimeInterval? = nil
    ) -> Template {
        Template(
            rider: Rider(id: UUID(), name: PersonNameComponents(givenName: givenName, familyName: familyName)),
            pickup: pickup,
            dropoff: dropoff,
            fare: Fare(amount: Decimal(cents) / 100, currencyCode: "USD"),
            riderCancelsAfter: riderCancelsAfter
        )
    }
}
