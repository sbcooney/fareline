import SwiftUI

/// The app's entry point, where dependencies are created and connected.
@main
struct FarelineApp: App {
    #if DEBUG
    private static let uiTestOptions = UITestLaunchOptions()
    #endif

    /// The app's one service, kept here so the demo menu can reach the mock as well as the model.
    private static let service = makeService()

    @State private var model = DriverModel(service: Self.service)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task {
                    await model.start()
                }
            #if DEBUG
                .environment(\.demoService, Self.service)
                .task {
                    await Self.uiTestOptions?.prepare(model)
                }
            #endif
        }
    }

    private static func makeService() -> MockRideService {
        #if DEBUG
        if let options = uiTestOptions {
            return options.makeService()
        }
        #endif
        return MockRideService(pastRideStore: .app, waitingRides: MockRideData.passedOverRides(at: .now))
    }
}
