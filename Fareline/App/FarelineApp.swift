import SwiftUI

/// The app's entry point, where dependencies are created and connected.
@main
struct FarelineApp: App {
    @State private var model = DriverModel(service: MockRideService(pastRideStore: .app))

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task {
                    await model.start()
                }
        }
    }
}
