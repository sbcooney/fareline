import SwiftUI

/// The driver's home screen, showing their status and the control that changes it.
struct AvailabilityView: View {
    let availability: DriverAvailability

    var body: some View {
        AvailabilityStatusView(availability: availability)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                AvailabilityButton(availability: availability)
                    .padding()
            }
    }
}

#Preview {
    AvailabilityView(availability: .offline)
        .environment(DriverStore(service: MockRideService()))
}
