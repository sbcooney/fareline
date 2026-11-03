import SwiftUI

/// Shows a pending offer over a pushed screen, so the driver sees it without losing their place.
struct OfferBanner: View {
    let offer: RideOffer

    /// Takes the driver to the offer screen.
    let open: () -> Void

    var body: some View {
        let fare = offer.ride.fare.amount.formatted(.currency(code: offer.ride.fare.currencyCode))

        Button(action: open) {
            HStack {
                VStack(alignment: .leading) {
                    Text("New Ride Offer")
                        .font(.headline)
                    Text("\(offer.ride.rider.name.formatted()), \(fare)")
                    OfferCountdownRow(expiresAt: offer.expiresAt)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
        .accessibilityHint("Opens the offer")
    }
}

#Preview {
    OfferBanner(
        offer: RideOffer(
            id: UUID(),
            ride: MockRideData.makeRide(sequence: 0, requestedAt: .now),
            driverID: MockRideData.driver.id,
            expiresAt: .now.addingTimeInterval(30)
        ),
        open: {}
    )
    .padding()
}
