#if DEBUG
import SwiftUI

extension EnvironmentValues {
    /// The mock service, so the demo menu can change what it simulates. Debug builds only.
    @Entry var demoService: MockRideService?
}

/// Lets a reviewer try situations that are hard to reach otherwise, such as losing the connection mid-ride.
///
/// Debug builds only. A real app learns about its connection from the system, not from a menu.
struct DemoMenu: View {
    @Environment(DriverModel.self) private var model
    @Environment(\.demoService) private var service

    var body: some View {
        if service != nil {
            Menu("Demo", systemImage: "wrench.and.screwdriver") {
                // The title follows the model's state, so it can't disagree with the toast and status button.
                Button(
                    model.isOffline ? "Restore Connection" : "Simulate No Connection",
                    systemImage: model.isOffline ? "wifi" : "wifi.slash",
                    action: toggleConnection
                )
            }
        }
    }

    private func toggleConnection() {
        let reconnects = model.isOffline
        Task { await service?.setConnected(reconnects) }
    }
}
#endif
