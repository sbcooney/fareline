import SwiftUI

/// Briefly tells the driver the connection dropped, that a ride step was saved for later, or that it's back.
///
/// Losing the connection is usually brief, so the message floats over the top of the content for a few seconds
/// rather than taking space that would move the screen. It ignores touches, so it never blocks a tap.
/// `ConnectionStatusButton` stays in the bar for a longer loss. VoiceOver hears these from `RootView`, so a screen
/// underneath a pushed one can't announce them twice.
struct ConnectionToast: View {
    @Environment(DriverModel.self) private var model

    /// The message showing, if any.
    @State private var message: LocalizedStringResource?

    var body: some View {
        VStack {
            if let message {
                Label {
                    Text(message)
                } icon: {
                    Image(systemName: model.isOffline ? "wifi.slash" : "wifi")
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.surfaceRaised, in: .capsule)
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: message)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: model.isOffline) { _, isOffline in
            show(isOffline ? Self.lostMessage : Self.restoredMessage(pendingStepCount: model.pendingSteps.count))
        }
        .onChange(of: model.pendingSteps.count) { oldCount, newCount in
            if model.isOffline, newCount > oldCount {
                show(Self.savedMessage)
            }
        }
        .task(id: message) {
            await hideAfterAWhile()
        }
    }

    private func show(_ newMessage: LocalizedStringResource) {
        message = newMessage
    }

    private func hideAfterAWhile() async {
        guard message != nil else {
            return
        }
        do {
            try await Task.sleep(for: .seconds(3))
        } catch {
            // A newer message replaced this one, and starts its own wait.
            return
        }
        message = nil
    }

    static let lostMessage: LocalizedStringResource = "No connection. Ride steps you take will be sent when it's back."

    static let savedMessage: LocalizedStringResource = "Saved. It'll be sent when the connection's back."

    /// What the toast says when the connection returns. The project has no String Catalog yet, so the singular is
    /// chosen here.
    static func restoredMessage(pendingStepCount: Int) -> LocalizedStringResource {
        switch pendingStepCount {
        case 0:
            "Connection restored."
        case 1:
            "Connection restored. Sending 1 ride step."
        default:
            "Connection restored. Sending \(pendingStepCount) ride steps."
        }
    }
}
