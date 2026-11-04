import SwiftUI

/// Tells the driver they're offline, and how many of their ride steps are waiting to be sent.
struct OfflineBanner: View {
    let pendingStepCount: Int

    var body: some View {
        Label {
            Text(Self.message(pendingStepCount: pendingStepCount))
        } icon: {
            Image(systemName: "wifi.slash")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.surfaceRaised)
        .accessibilityElement(children: .combine)
    }

    /// The banner's text. The project has no String Catalog yet, so the singular is chosen here.
    static func message(pendingStepCount: Int) -> LocalizedStringResource {
        switch pendingStepCount {
        case 0:
            "You're offline. Ride steps you take will be sent when you reconnect."
        case 1:
            "You're offline. 1 ride step will be sent when you reconnect."
        default:
            "You're offline. \(pendingStepCount) ride steps will be sent when you reconnect."
        }
    }
}

#Preview {
    VStack {
        OfflineBanner(pendingStepCount: 0)
        OfflineBanner(pendingStepCount: 2)
    }
}
