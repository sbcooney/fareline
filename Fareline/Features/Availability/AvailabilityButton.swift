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
        .accessibilityValue(store.isPerformingAction ? Text("Updating") : Text(""))
    }

    private func changeAvailability() {
        Task {
            await store.changeAvailability()
        }
    }
}

#Preview {
    AvailabilityButton(availability: .offline)
        .environment(DriverStore(service: MockRideService()))
}
