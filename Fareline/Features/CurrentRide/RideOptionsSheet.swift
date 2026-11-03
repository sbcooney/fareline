import SwiftUI

/// The ride's less common actions, as a short list the driver chooses from.
///
/// It holds Cancel Ride, which asks for a confirmation that explains what cancelling means at this stage.
/// Either answer closes the sheet, as the driver has decided.
struct RideOptionsSheet: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let ride: Ride

    /// The ride the driver asked to cancel, while the confirmation is showing.
    @State private var rideToCancel: Ride?

    /// The height of the sheet's content once it's measured, so the sheet is only as tall as its options.
    @State private var contentHeight: CGFloat?

    var body: some View {
        VStack(spacing: 16) {
            Text("Ride Options")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Button(role: .destructive) {
                rideToCancel = ride
            } label: {
                Label("Cancel Ride", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            // The destructive role colors only the text, so the icon is matched to it.
            .tint(.red)
        }
        .padding()
        // The grabber, swiping down, tapping outside, and VoiceOver's escape gesture all close the sheet.
        .padding(.top)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { height in
            contentHeight = height
        }
        // A height of zero isn't a valid detent, so the sheet uses half the screen until its content is measured.
        .presentationDetents(contentHeight.map { [.height($0)] } ?? [.medium])
        .presentationDragIndicator(.visible)
        .alert("Cancel This Ride?", item: $rideToCancel) { ride in
            Button("Cancel Ride", role: .destructive) {
                // The sheet closes first, so an error from the request can show on the ride screen.
                dismiss()
                Task { await model.cancelRide(rideID: ride.id) }
            }
            Button("Keep Ride", role: .cancel) {
                dismiss()
            }
        } message: { ride in
            if let message = ride.status.cancellationMessage {
                Text(message)
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

    Text("Current ride")
        .sheet(isPresented: .constant(true)) {
            RideOptionsSheet(ride: ride)
        }
        .environment(model)
}
