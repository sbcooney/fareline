import SwiftUI

/// The app's top-level view, which provides navigation and shows alerts from anywhere in the app.
struct RootView: View {
    @Environment(DriverModel.self) private var model

    var body: some View {
        @Bindable var model = model

        NavigationStack {
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
