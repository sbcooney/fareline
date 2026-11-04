import SwiftUI

/// Lets the driver accept or decline an offer, showing progress while the service responds.
struct OfferResponseButtons: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let offerID: RideOffer.ID

    private var isDisabled: Bool {
        model.isPerformingAction || model.isOffline || isReady == false
    }

    /// Whether the buttons have been showing long enough to take a tap. See ``ignoreTapsBriefly()``.
    @State private var isReady = false

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

                Button(action: accept) {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                // In dark mode the brand color is light, so white text on it wouldn't be readable. A disabled button
                // keeps the system's dimmed label, so it doesn't look tappable.
                .foregroundStyle(isDisabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.textOnBrand))
                .accessibilityValue(model.isPerformingAction ? Text("Updating") : Text(""))
            }
        }
        .controlSize(.large)
        .disabled(isDisabled)
        .task(id: offerID, ignoreTapsBriefly)
        .overlay {
            if model.isPerformingAction {
                ProgressView()
            }
        }
    }

    /// Accept appears where Go Offline was, so a tap meant for Go Offline could otherwise take the ride.
    /// `AvailabilityButton` uses the same delay.
    private func ignoreTapsBriefly() async {
        isReady = false
        do {
            try await Task.sleep(for: .seconds(0.75))
        } catch {
            // A cancelled wait belongs to an offer that's gone, so it mustn't ready the buttons for the next one.
            return
        }
        isReady = true
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
