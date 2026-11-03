import SwiftUI

/// Changes the driver's status, showing progress while the service responds.
struct AvailabilityButton: View {
    @Environment(DriverModel.self) private var model

    let availability: DriverAvailability

    /// Whether the button has been showing long enough to take a tap. See ``ignoreTapsBriefly()``.
    @State private var isReady = false

    var body: some View {
        Button(action: changeAvailability) {
            // The title stays in the layout during a request, so the button's size doesn't change.
            Text(availability.actionTitle)
                .opacity(model.isPerformingAction ? 0 : 1)
                .overlay {
                    if model.isPerformingAction {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(model.canChangeAvailability == false || isReady == false)
        .task(id: availability, ignoreTapsBriefly)
        // VoiceOver can skip fully transparent text, so the name is set explicitly.
        .accessibilityLabel(Text(availability.actionTitle))
        .accessibilityValue(model.isPerformingAction ? Text("Updating") : Text(""))
    }

    /// Go Offline appears where Accept was when an offer ends, and where Go Online was after going online, so a
    /// tap meant for those could otherwise take the driver offline. `OfferResponseButtons` uses the same delay.
    private func ignoreTapsBriefly() async {
        isReady = false
        do {
            try await Task.sleep(for: .seconds(0.75))
        } catch {
            // A cancelled wait belongs to a status that's gone, so it mustn't ready the button for the next one.
            return
        }
        isReady = true
    }

    /// Requests the change this button's title describes.
    ///
    /// This uses the status the button was drawn with rather than the latest one, so that a tap can
    /// never do the opposite of what the driver read.
    private func changeAvailability() {
        Task {
            switch availability {
            case .offline:
                await model.goOnline()
            case .available:
                await model.goOffline()
            case .onRide:
                break
            }
        }
    }
}
