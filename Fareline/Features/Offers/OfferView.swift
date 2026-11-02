import SwiftUI

/// Shows an incoming ride offer, with what the driver needs to decide whether to take it.
struct OfferView: View {
    let offer: RideOffer

    var body: some View {
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

#Preview {
    NavigationStack {
        OfferView(
            offer: RideOffer(
                id: UUID(),
                ride: MockRideData.makeRide(sequence: 0, requestedAt: .now),
                driverID: MockRideData.driver.id,
                expiresAt: .now.addingTimeInterval(30)
            )
        )
    }
}
