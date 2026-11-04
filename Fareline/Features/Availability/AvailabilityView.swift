import SwiftUI

/// The driver's home screen, showing their status and the control that changes it.
struct AvailabilityView: View {
    @Environment(DriverModel.self) private var model

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
            VStack {
                // The button is disabled offline, so this says why.
                if model.isOffline {
                    Text("Changing your status needs a connection.")
                        .font(.footnote)
                        .foregroundStyle(.textSecondary)
                }
                AvailabilityButton(availability: availability)
            }
            .padding()
        }
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())

    NavigationStack {
        AvailabilityView(availability: .offline)
    }
    .environment(model)
    .task {
        await model.start()
    }
}
