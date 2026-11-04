import SwiftUI

/// The app's top-level view, which provides navigation, and shows alerts and offers from anywhere in the app.
struct RootView: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var navigation = AppNavigation()

    /// The offer to show in the pending offer bar: one that arrives while the driver is on a pushed screen.
    private var barOffer: RideOffer? {
        navigation.path.isEmpty ? nil : model.session?.pendingOffer
    }

    /// Whether the home screen is showing, rather than an offer, a ride, or the connecting state.
    private var isShowingHome: Bool {
        guard let session = model.session else {
            return false
        }
        return session.activeRide == nil && session.pendingOffer == nil
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
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
            // Over the content rather than beside it, so nothing moves when the connection drops.
            .overlay(alignment: .top) {
                ConnectionToast()
            }
            .navigationDestination(for: AppDestination.self, destination: AppDestinationView.init)
            // The buttons live here rather than on the home screen, because an offer can replace the home screen
            // mid-tap. A link on the disappearing screen crashed SwiftUI. Changing the path here is always safe.
            .toolbar {
                if isShowingHome {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Waiting Riders", systemImage: "person.2", action: openWaitingRiders)
                        Button("Past Rides", systemImage: "clock", action: openPastRides)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ConnectionStatusButton()
                }
                // On every root screen, so the connection can be lost mid-ride.
                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    DemoMenu()
                }
                #endif
            }
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
        .onChange(of: model.session?.activeRide?.id) { oldID, id in
            if id != nil {
                navigation.rideStarted()
            } else if oldID != nil {
                navigation.rideEnded(cancelledByDriver: model.session?.pastRides.first?.cancelledBy == .driver)
            }
        }
        .onChange(of: model.session?.activeRide?.status) { _, status in
            if status == .inProgress {
                navigation.tripStarted()
            }
        }
        .onChange(of: model.session?.pendingOffer?.id) { _, id in
            announceNewOffer()
            if id == nil {
                navigation.offerEnded(rideStarted: model.session?.activeRide != nil)
            }
        }
        .onChange(of: model.isOffline) {
            announceConnection()
        }
        .onChange(of: model.pendingSteps.count) { oldCount, newCount in
            if model.isOffline, newCount > oldCount {
                AccessibilityNotification.Announcement(String(localized: ConnectionToast.savedMessage)).post()
            }
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

    private func openPastRides() {
        navigation.open(.pastRides)
    }

    private func openWaitingRiders() {
        navigation.open(.waitingRiders)
    }

    private func openOffer() {
        navigation.openOffer()
    }

    /// Tells VoiceOver users the connection changed, as the toast is hidden from VoiceOver to avoid repeating it.
    private func announceConnection() {
        let announcement = model.isOffline
            ? ConnectionToast.lostMessage
            : ConnectionToast.restoredMessage(pendingStepCount: model.pendingSteps.count)
        AccessibilityNotification.Announcement(String(localized: announcement)).post()
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
