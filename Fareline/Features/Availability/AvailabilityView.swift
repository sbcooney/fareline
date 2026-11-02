import SwiftUI

/// The driver's home screen, showing their status and the control that changes it.
struct AvailabilityView: View {
    let availability: DriverAvailability

    var body: some View {
        // Scrolling keeps the status readable at the largest text sizes.
        ScrollView {
            AvailabilityStatusView(availability: availability)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            AvailabilityButton(availability: availability)
                .padding()
        }
    }
}

#Preview {
    @Previewable @State var store = DriverStore(service: MockRideService())

    AvailabilityView(availability: .offline)
        .environment(store)
        .task {
            await store.start()
        }
}
