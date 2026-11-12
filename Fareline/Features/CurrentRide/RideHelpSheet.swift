import SwiftUI

/// Ways for a driver waiting at pickup to reach the rider or Fareline, or to cancel.
///
/// The calls open `tel:` links, so iOS asks the driver to confirm before dialing. A device that can't make calls,
/// such as the Simulator, shows the number instead. Cancel Ride asks for the same confirmation as in
/// ``RideOptionsSheet``, and either answer closes the sheet.
struct RideHelpSheet: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let ride: Ride

    /// The ride the driver asked to cancel, while the confirmation is showing.
    @State private var rideToCancel: Ride?

    /// The number the driver tried to call on a device that can't make calls, while the alert is showing.
    @State private var failedCallNumber: String?

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
            if let phoneNumber = ride.rider.phoneNumber {
                Button {
                    call(phoneNumber)
                } label: {
                    Label("Call Rider", systemImage: "phone")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            Button {
                call(Self.supportPhoneNumber)
            } label: {
                Label("Contact Fareline Support", systemImage: "questionmark.bubble")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
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
        .alert("Can't Make Calls on This Device", item: $failedCallNumber) { _ in
        } message: { phoneNumber in
            Text("Call \(phoneNumber) from a phone instead.")
        }
    }

    /// Asks iOS to dial the number, and shows it in an alert if this device can't make calls.
    ///
    /// A `Link` would fail silently, which looks broken in the Simulator, where reviewers run the app.
    private func call(_ phoneNumber: String) {
        guard let url = URL(string: "tel:\(phoneNumber)") else {
            return
        }
        openURL(url) { accepted in
            if accepted == false {
                failedCallNumber = phoneNumber
            }
        }
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
