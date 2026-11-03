import SwiftUI

/// The app's top-level view, which provides navigation, and shows alerts and offers from anywhere in the app.
struct RootView: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [AppDestination] = []

    /// The offer to show in the pending offer bar: one that arrives while the driver is on a pushed screen.
    private var barOffer: RideOffer? {
        path.isEmpty ? nil : model.session?.pendingOffer
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            Group {
                if let ride = model.session?.activeRide {
                    CurrentRideView(ride: ride)
                } else if let offer = model.session?.pendingOffer {
                    OfferView(offer: offer)
                } else if let session = model.session {
                    AvailabilityView(availability: session.driver.availability)
                } else {
                    ProgressView("Connecting")
                }
            }
            .navigationDestination(for: AppDestination.self, destination: AppDestinationView.init)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                if let offer = barOffer {
                    PendingOfferBar(offer: offer, open: openOffer)
                        .padding()
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.default, value: barOffer?.id)
        }
        // A ride replaces the root screen, and unlike an offer it has no bar, so the driver is taken to it.
        .onChange(of: model.session?.activeRide?.id) { _, id in
            if id != nil {
                path.removeAll()
            }
        }
        .onChange(of: model.session?.pendingOffer?.id) {
            announceNewOffer()
        }
        .onChange(of: model.unansweredOfferID) {
            AccessibilityNotification.Announcement("The ride offer ended.").post()
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: model.session?.pendingOffer?.id) { _, offerID in
            offerID != nil
        }
        // A single "OK" that only dismisses is supplied by the system when no actions are given.
        .alert(model.alert?.title ?? "", item: $model.alert) { _ in
        } message: { alert in
            Text(alert.message)
        }
    }

    /// Returns to the root screen, where a pending offer is shown.
    private func openOffer() {
        path.removeAll()
    }

    /// Tells VoiceOver users about a new offer, which they might not notice replacing the screen.
    private func announceNewOffer() {
        guard let ride = model.session?.pendingOffer?.ride else {
            return
        }
        let fare = ride.fare.amount.formatted(.currency(code: ride.fare.currencyCode))
        AccessibilityNotification.Announcement(
            "New ride offer from \(ride.rider.name.formatted()), for \(fare)."
        ).post()
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())

    RootView()
        .environment(model)
        .task {
            await model.start()
        }
}
