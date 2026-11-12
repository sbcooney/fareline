import SwiftUI

/// Ways for a driver waiting at pickup to reach the rider or Fareline, or to cancel.
///
/// The calls open `tel:` links, so iOS asks the driver to confirm before dialing. Cancel Ride asks for the same
/// confirmation as in ``RideOptionsSheet``, and either answer closes the sheet.
struct RideHelpSheet: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let ride: Ride

    /// The ride the driver asked to cancel, while the confirmation is showing.
    @State private var rideToCancel: Ride?

    /// The height of the sheet's content once it's measured, so the sheet is only as tall as its options.
    @State private var contentHeight: CGFloat?

    /// Fareline's support line, a fictional 555 number.
    private static let supportPhoneNumber = "202-555-0100"

    var body: some View {
        VStack(spacing: 16) {
            Text("Help")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            // Rides saved before riders had numbers have none, but a ride in progress always has one.
            if let url = ride.rider.phoneNumber.flatMap(Self.callURL(for:)) {
                Link(destination: url) {
                    Label("Call Rider", systemImage: "phone")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            if let url = Self.callURL(for: Self.supportPhoneNumber) {
                Link(destination: url) {
                    Label("Contact Fareline Support", systemImage: "questionmark.bubble")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
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

    /// Returns a link that dials the number.
    private static func callURL(for phoneNumber: String) -> URL? {
        URL(string: "tel:\(phoneNumber)")
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())
    let ride = {
        var ride = MockRideData.makeRide(sequence: 0, requestedAt: .now)
        try? ride.apply(.driverAssigned(driverID: MockRideData.driver.id))
        try? ride.apply(.driverArrived)
        return ride
    }()

    Text(verbatim: "Current ride")
        .sheet(isPresented: .constant(true)) {
            RideHelpSheet(ride: ride)
        }
        .environment(model)
}
