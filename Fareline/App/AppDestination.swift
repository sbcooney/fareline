import SwiftUI

/// The screens that can be pushed onto the app's navigation stack.
///
/// To add a screen, add a case here and push it with a `NavigationLink(value:)`. The compiler then requires a
/// matching view in ``AppDestinationView``.
enum AppDestination: Hashable {
    /// The driver's past rides.
    case pastRides

    /// One past ride's details.
    case pastRide(Ride.ID)

    /// The riders that no driver has taken.
    case waitingRiders
}

/// Maps each destination to its view.
struct AppDestinationView: View {
    let destination: AppDestination

    var body: some View {
        Group {
            switch destination {
            case .pastRides:
                PastRidesView()
            case .pastRide(let id):
                PastRideDetailView(rideID: id)
            case .waitingRiders:
                WaitingRidersView()
            }
        }
        // Pushed screens show the offline banner below their navigation bar too, as the root screen does.
        .safeAreaBar(edge: .top, spacing: 0) {
            OfflineBanner()
        }
    }
}
