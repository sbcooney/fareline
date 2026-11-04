import SwiftUI

/// The app's top-level view, which provides navigation, and shows alerts and offers from anywhere in the app.
struct RootView: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [AppDestination] = []

    /// The screens the driver was on when they opened an offer from the bar, to return to if it ends without a ride
    /// starting, such as Waiting Riders after a decline.
    @State private var pathBeforeOffer: [AppDestination]?

    /// Whether the current ride was taken from Waiting Riders and its trip hasn't started, so cancelling it returns
    /// the driver to the list they were choosing from.
    @State private var returnsToWaitingRiders = false

    /// The offer to show in the pending offer bar: one that arrives while the driver is on a pushed screen.
    private var barOffer: RideOffer? {
        path.isEmpty ? nil : model.session?.pendingOffer
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
            // The buttons live here rather than on the home screen, because an offer can replace the home screen
            // mid-tap. A link on the disappearing screen crashed SwiftUI. Changing the path here is always safe.
            .toolbar {
                if isShowingHome {
                    Button("Waiting Riders", systemImage: "person.2", action: openWaitingRiders)
                    Button("Past Rides", systemImage: "clock", action: openPastRides)
                }
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
        // A ride replaces the root screen, and unlike an offer it has no bar, so the driver is taken to it.
        .onChange(of: model.session?.activeRide?.id) { oldID, id in
            if id != nil {
                startRide()
            } else if oldID != nil {
                endRide()
            }
        }
        .onChange(of: model.session?.activeRide?.status) { _, status in
            // Once the rider is in the car, a cancelled ride is over rather than a reason to choose another.
            if status == .inProgress {
                returnsToWaitingRiders = false
            }
        }
        .onChange(of: model.session?.pendingOffer?.id) { _, id in
            announceNewOffer()
            if id == nil {
                returnToPathBeforeOffer()
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
        path.append(.pastRides)
    }

    private func openWaitingRiders() {
        path.append(.waitingRiders)
    }

    /// Returns to the root screen, where a pending offer is shown.
    private func openOffer() {
        pathBeforeOffer = path
        path.removeAll()
    }

    /// Makes a ride the root screen. A ride taken from Waiting Riders remembers it, so cancelling can return there.
    private func startRide() {
        returnsToWaitingRiders = path.last == .waitingRiders
        path.removeAll()
        pathBeforeOffer = nil
    }

    /// Returns to Waiting Riders after the driver cancels a ride they took from it, before the trip started.
    private func endRide() {
        defer { returnsToWaitingRiders = false }
        if returnsToWaitingRiders, model.session?.pastRides.first?.cancelledBy == .driver {
            path = [.waitingRiders]
        }
    }

    /// Puts back the screens the driver left to see an offer, once it ends without a ride starting: declined,
    /// expired, or withdrawn. An accepted offer starts a ride, which stays the root screen.
    private func returnToPathBeforeOffer() {
        guard let savedPath = pathBeforeOffer else {
            return
        }
        pathBeforeOffer = nil
        if model.session?.activeRide == nil {
            path = savedPath
        }
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
