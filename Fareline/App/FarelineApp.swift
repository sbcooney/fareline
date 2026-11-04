import SwiftUI

/// The app's entry point, where dependencies are created and connected.
@main
struct FarelineApp: App {
    @State private var model = DriverModel(service: Self.makeService())

    #if DEBUG
    private static let uiTestOptions = UITestLaunchOptions()
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task {
                    await model.start()
                }
            #if DEBUG
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
