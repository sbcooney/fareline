import SwiftUI

/// The ride's less common actions, kept in a menu so they stay away from the driver's next step.
///
/// It holds Cancel Ride, which asks for a confirmation that explains what cancelling means at this stage.
struct RideOptionsMenu: View {
    @Environment(DriverModel.self) private var model

    let ride: Ride

    /// The ride the driver asked to cancel, while the confirmation is showing.
    ///
    /// The confirmation keeps the ride it opened for, so confirming cancels that ride even if the screen has
    /// changed behind it.
    @State private var rideToCancel: Ride?

    var body: some View {
        if ride.status.canBeCancelled(by: .driver) {
            Menu {
                Button("Cancel Ride", systemImage: "xmark.circle", role: .destructive) {
                    rideToCancel = ride
                }
            } label: {
                if model.isCancellingRide {
                    ProgressView()
                } else {
                    Label("Ride Options", systemImage: "ellipsis")
                }
            }
            .disabled(model.isPerformingAction)
            // The progress view replaces the label while cancelling, so the name is set explicitly.
            .accessibilityLabel(Text("Ride Options"))
            .accessibilityValue(model.isCancellingRide ? Text("Updating") : Text(""))
            // Attached to the menu rather than the button inside it, which goes away when the menu closes, so the
            // confirmation has a view to appear from.
            .confirmationDialog("Cancel This Ride?", item: $rideToCancel, titleVisibility: .visible) { ride in
                Button("Cancel Ride", role: .destructive) {
                    Task { await model.cancelRide(rideID: ride.id) }
                }
                Button("Keep Ride", role: .cancel) {}
            } message: { ride in
                if let message = ride.status.cancellationMessage {
                    Text(message)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())
    let ride = {
        var ride = MockRideData.makeRide(sequence: 0, requestedAt: .now)
        try? ride.apply(.driverAssigned(driverID: MockRideData.driver.id))
        return ride
    }()

    NavigationStack {
        Text("Current ride")
            .toolbar {
                RideOptionsMenu(ride: ride)
            }
    }
    .environment(model)
}
