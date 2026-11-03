import SwiftUI

/// A bar pinned to the bottom of a pushed screen that shows a pending offer, so the driver sees it without
/// losing their place. It stays until the driver opens the offer or the offer ends.
struct PendingOfferBar: View {
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
                    .foregroundStyle(.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // A solid, raised card with a brand-colored edge, so an urgent offer stands apart from the list behind it.
        .background(.surfaceRaised, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.brandPrimary, lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .accessibilityHint("Opens the offer")
    }
}

#Preview {
    PendingOfferBar(
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
