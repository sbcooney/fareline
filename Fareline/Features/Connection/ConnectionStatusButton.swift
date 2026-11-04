import SwiftUI

/// Shows in the navigation bar while there's no connection, so a longer loss stays visible after the toast has gone,
/// such as for an available driver wondering why no offers are arriving. Tapping it explains what works.
struct ConnectionStatusButton: View {
    @Environment(DriverModel.self) private var model

    @State private var isShowingExplanation = false

    var body: some View {
        if model.isOffline {
            Button("No Connection", systemImage: "wifi.slash", action: showExplanation)
                .badge(model.pendingSteps.count)
                .popover(isPresented: $isShowingExplanation) {
                    Text(Self.explanation(pendingStepCount: model.pendingSteps.count))
                        .padding()
                        .frame(idealWidth: 280)
                        .presentationCompactAdaptation(.popover)
                }
        }
    }

    private func showExplanation() {
        isShowingExplanation = true
    }

    /// The popover's text. The project has no String Catalog yet, so the singular is chosen here.
    static func explanation(pendingStepCount: Int) -> LocalizedStringResource {
        switch pendingStepCount {
        case 0:
            """
            No connection. Ride steps you take will be sent when it's back. \
            Offers, changing your status, and taking a ride need a connection.
            """
        case 1:
            """
            No connection. 1 ride step will be sent when it's back. \
            Offers, changing your status, and taking a ride need a connection.
            """
        default:
            """
            No connection. \(pendingStepCount) ride steps will be sent when it's back. \
            Offers, changing your status, and taking a ride need a connection.
            """
        }
    }
}
