import SwiftUI

/// Tells the driver the connection is lost, and how many of their ride steps are waiting to be sent.
///
/// It says "no connection" rather than "offline", which the app already uses for a driver who isn't taking rides.
///
/// Each screen shows it below its navigation bar, so it never covers the bar's buttons. It shows nothing online.
struct OfflineBanner: View {
    @Environment(DriverModel.self) private var model

    var body: some View {
        if model.isOffline {
            Label {
                Text(Self.message(pendingStepCount: model.pendingSteps.count))
            } icon: {
                Image(systemName: "wifi.slash")
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.surfaceRaised)
            .accessibilityElement(children: .combine)
        }
    }

    /// The banner's text. The project has no String Catalog yet, so the singular is chosen here.
    static func message(pendingStepCount: Int) -> LocalizedStringResource {
        switch pendingStepCount {
        case 0:
            "No connection. Ride steps you take will be sent when it's back."
        case 1:
            "No connection. 1 ride step will be sent when it's back."
        default:
            "No connection. \(pendingStepCount) ride steps will be sent when it's back."
        }
    }
}

#Preview {
    @Previewable @State var model = DriverModel(service: MockRideService())

    OfflineBanner()
        .environment(model)
}
