import SwiftUI

/// Changes the driver's status, showing progress while the service responds.
struct AvailabilityButton: View {
    @Environment(DriverStore.self) private var store

    let availability: DriverAvailability

    var body: some View {
        Button(action: changeAvailability) {
            // The title stays in the layout during a request, so the button's size doesn't change.
            Text(availability.actionTitle)
                .opacity(store.isPerformingAction ? 0 : 1)
                .overlay {
                    if store.isPerformingAction {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(store.canChangeAvailability == false)
        // VoiceOver can skip fully transparent text, so the name is set explicitly.
        .accessibilityLabel(Text(availability.actionTitle))
        .accessibilityValue(store.isPerformingAction ? Text("Updating") : Text(""))
    }

    /// Requests the change this button's title describes.
    ///
    /// This uses the status the button was drawn with rather than the latest one, so that a tap can
    /// never do the opposite of what the driver read.
    private func changeAvailability() {
        Task {
            switch availability {
            case .offline:
                await store.goOnline()
            case .available:
                await store.goOffline()
            case .onRide:
                break
            }
        }
    }
}
