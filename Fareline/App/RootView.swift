import SwiftUI

/// The app's top-level view, which chooses a screen and shows errors from any driver action.
struct RootView: View {
    @Environment(DriverStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Group {
            if let session = store.session {
                if let offer = session.pendingOffer {
                    OfferView(offer: offer)
                } else {
                    AvailabilityView(availability: session.driver.availability)
                }
            } else {
                ProgressView("Connecting")
            }
        }
        .alert("Something Went Wrong", isPresented: $store.isShowingError, presenting: store.lastError) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.message)
        }
    }
}

#Preview {
    @Previewable @State var store = DriverStore(service: MockRideService())

    RootView()
        .environment(store)
        .task {
            await store.start()
        }
}
