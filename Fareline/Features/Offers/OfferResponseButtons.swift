import SwiftUI

/// Lets the driver accept or decline an offer, showing progress while the service responds.
struct OfferResponseButtons: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let offerID: RideOffer.ID

    var body: some View {
        // The buttons stack at the largest text sizes, where side by side they'd run out of room.
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())

        VStack {
            // The buttons are disabled offline, so this says why.
            if model.isOffline {
                Text("Answering an offer needs a connection.")
                    .font(.footnote)
                    .foregroundStyle(.textSecondary)
            }
            layout {
                Button(action: decline) {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityValue(model.isPerformingAction ? Text("Updating") : Text(""))

                // Progress shows over both buttons, as either could be the one waiting, so Accept shows none itself.
                PrimaryActionButton(title: "Accept", action: accept)
                    .accessibilityValue(model.isPerformingAction ? Text("Updating") : Text(""))
            }
        }
        .controlSize(.large)
        .disabled(model.canAnswerOffer == false)
        // Accept appears where Go Offline was, so a tap meant for Go Offline could otherwise take the ride.
        .ignoresTapsBriefly(after: offerID)
        .overlay {
            if model.isPerformingAction {
                ProgressView()
            }
        }
    }

    private func accept() {
        Task {
            await model.acceptOffer(id: offerID)
        }
    }

    private func decline() {
        Task {
            await model.declineOffer(id: offerID)
        }
    }
}
