import SwiftUI

/// Shows an incoming ride offer, with what the driver needs to decide whether to take it.
struct OfferView: View {
    let offer: RideOffer

    var body: some View {
        NavigationStack {
            List {
                Section {
                    OfferCountdownRow(expiresAt: offer.expiresAt)
                }
                Section {
                    LabeledContent("Rider", value: offer.ride.rider.name.formatted())
                    LabeledContent(
                        "Estimated Fare",
                        value: offer.ride.fare.amount,
                        format: .currency(code: offer.ride.fare.currencyCode)
                    )
                }
                Section {
                    PlaceRow(title: "Pickup", place: offer.ride.pickup)
                    PlaceRow(title: "Drop-off", place: offer.ride.dropoff)
                }
            }
            .navigationTitle("New Ride Offer")
        }
    }
}

#Preview {
    OfferView(
        offer: RideOffer(
            id: UUID(),
            ride: Ride(
                id: UUID(),
                rider: Rider(id: UUID(), name: PersonNameComponents(givenName: "Ada", familyName: "Lovelace")),
                pickup: Place(name: "Union Station", address: "50 Massachusetts Ave NE"),
                dropoff: Place(name: "National Mall", address: "900 Ohio Dr SW"),
                fare: Fare(amount: 18.40, currencyCode: "USD"),
                requestedAt: .now
            ),
            driverID: UUID(),
            expiresAt: .now.addingTimeInterval(30)
        )
    )
}
