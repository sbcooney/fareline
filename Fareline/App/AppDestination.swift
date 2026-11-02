import SwiftUI

/// The screens that can be pushed onto the app's navigation stack.
///
/// To add a screen, add a case here and push it with a `NavigationLink(value:)`. The compiler then requires a
/// matching view in ``AppDestinationView``.
enum AppDestination: Hashable {
    /// Nothing links here yet. The screen is built in #8.
    case pastRides
}

/// Maps each destination to its view.
struct AppDestinationView: View {
    let destination: AppDestination

    var body: some View {
        switch destination {
        case .pastRides:
            ContentUnavailableView("No Past Rides", systemImage: "clock")
        }
    }
}
