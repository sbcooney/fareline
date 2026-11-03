import SwiftUI

/// Lets the driver accept or decline an offer, showing progress while the service responds.
struct OfferResponseButtons: View {
    @Environment(DriverStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let offerID: RideOffer.ID

    var body: some View {
        // The buttons stack at the largest text sizes, where side by side they'd run out of room.
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())

        layout {
            Button(action: decline) {
                Text("Decline")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityValue(store.isPerformingAction ? Text("Updating") : Text(""))

            Button(action: accept) {
                Text("Accept")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityValue(store.isPerformingAction ? Text("Updating") : Text(""))
        }
        .controlSize(.large)
        .disabled(store.isPerformingAction)
        .overlay {
            if store.isPerformingAction {
                ProgressView()
            }
        }
    }

    private func accept() {
        Task {
            await store.acceptOffer(id: offerID)
        }
    }

    private func decline() {
        Task {
            await store.declineOffer(id: offerID)
        }
    }
}
