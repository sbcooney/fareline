import SwiftUI

/// The app's entry point, where dependencies are created and connected.
@main
struct FarelineApp: App {
    @State private var store = DriverStore(service: MockRideService())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task {
                    await store.start()
                }
        }
    }
}
