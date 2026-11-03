import SwiftUI

/// The app's entry point, where dependencies are created and connected.
@main
struct FarelineApp: App {
    @State private var model = DriverModel(service: Self.makeService())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task {
                    await model.start()
                }
            #if DEBUG
                .task {
                    await UITestLaunchOptions()?.prepare(model)
                }
            #endif
        }
    }

    private static func makeService() -> MockRideService {
        #if DEBUG
        if let options = UITestLaunchOptions() {
            return options.makeService()
        }
        #endif
        return MockRideService(pastRideStore: .app)
    }
}
