import SwiftUI

/// Cancels the driver's ride, after a confirmation that explains what cancelling means at this stage.
struct CancelRideButton: View {
    @Environment(DriverModel.self) private var model

    let ride: Ride

    /// The ride the driver asked to cancel, while the confirmation is showing.
    ///
    /// The confirmation keeps the ride it opened for, so confirming cancels that ride even if the screen has
    /// changed behind it.
    @State private var rideToCancel: Ride?

    var body: some View {
        if ride.status.canBeCancelled(by: .driver) {
            Button(role: .destructive) {
                rideToCancel = ride
            } label: {
                // The title stays in the layout during the request, so the button's size doesn't change.
                Text("Cancel Ride")
                    .opacity(model.isCancellingRide ? 0 : 1)
                    .overlay {
                        if model.isCancellingRide {
                            ProgressView()
                        }
                    }
            }
            .disabled(model.isPerformingAction)
            // VoiceOver can skip fully transparent text, so the name is set explicitly.
            .accessibilityLabel(Text("Cancel Ride"))
            .accessibilityValue(model.isCancellingRide ? Text("Updating") : Text(""))
            // Attached to the button, so the confirmation appears from the control that opened it.
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

    CancelRideButton(ride: ride)
        .environment(model)
}
