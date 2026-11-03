import SwiftUI

/// The app's top-level view, which provides navigation and shows alerts from anywhere in the app.
struct RootView: View {
    @Environment(DriverModel.self) private var model
    @State private var path: [AppDestination] = []

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
        // An offer or a ride replaces the root screen, so a pushed screen would hide it. Returning to the
        // root shows it.
        .onChange(of: model.session?.activeRide?.id ?? model.session?.pendingOffer?.id) { _, id in
            if id != nil {
                path.removeAll()
            }
        }
        .alert("Something Went Wrong", isPresented: $model.isShowingError, presenting: model.lastError) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.message)
        }
        .alert("Ride Cancelled", isPresented: $model.isShowingCancelledRide, presenting: model.cancelledRide) { _ in
            Button("OK", role: .cancel) {}
        } message: { ride in
            Text("\(ride.rider.name.formatted()) cancelled the ride. You're available for new offers.")
        }
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
