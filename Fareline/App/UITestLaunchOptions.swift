#if DEBUG
import Foundation

/// Launch arguments that UI tests pass to start the app in a known state. Debug builds only.
///
/// - `-uiTesting`: use a fresh mock with no saved history, rather than the demo setup.
/// - `-seedPastRides`: start with one completed and one cancelled past ride.
/// - `-goOnline`: go online at launch.
/// - `-offerDelay <seconds>`: how long each offer takes to arrive. The default is 1 second.
/// - `-acceptFirstOffer`: accept the first offer, to reach the current ride screen.
struct UITestLaunchOptions {
    let seedsPastRides: Bool
    let goesOnline: Bool
    let offerDelay: TimeInterval
    let acceptsFirstOffer: Bool

    /// Reads the options, or returns `nil` if the app wasn't launched by a UI test.
    init?(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard arguments.contains("-uiTesting") else {
            return nil
        }
        seedsPastRides = arguments.contains("-seedPastRides")
        goesOnline = arguments.contains("-goOnline")
        acceptsFirstOffer = arguments.contains("-acceptFirstOffer")
        let delayIndex = arguments.firstIndex(of: "-offerDelay").map { $0 + 1 }
        offerDelay = delayIndex.flatMap { arguments.indices.contains($0) ? TimeInterval(arguments[$0]) : nil } ?? 1
    }

    /// Returns a mock service with its own history file, so each launch starts from the same state.
    func makeService() -> MockRideService {
        var configuration = MockRideServiceConfiguration.demo
        configuration.offerDelay = offerDelay
        let pastRideStore = PastRideStore(
            fileURL: .temporaryDirectory.appending(path: "UITestPastRides-\(UUID().uuidString).json")
        )
        if seedsPastRides {
            try? pastRideStore.save(Self.seededPastRides())
        }
        return MockRideService(configuration: configuration, pastRideStore: pastRideStore)
    }

    /// Takes the actions the options ask for. The model must already be receiving session updates.
    @MainActor
    func prepare(_ model: DriverModel) async {
        guard goesOnline else {
            return
        }
        await model.goOnline()
        guard acceptsFirstOffer else {
            return
        }
        for await offerID in Observations({ model.session?.pendingOffer?.id }) {
            if let offerID {
                await model.acceptOffer(id: offerID)
                return
            }
        }
    }

    /// Returns a cancelled ride and a completed one, newest first, as the service saves them.
    private static func seededPastRides() -> [Ride] {
        let now = Date.now
        var completed = MockRideData.makeRide(sequence: 0, requestedAt: now.addingTimeInterval(-7_200))
        try? completed.apply(.driverAssigned(driverID: MockRideData.driver.id))
        try? completed.apply(.driverArrived)
        try? completed.apply(.tripStarted)
        try? completed.apply(.tripCompleted(date: now.addingTimeInterval(-6_000)))

        var cancelled = MockRideData.makeRide(sequence: 1, requestedAt: now.addingTimeInterval(-3_600))
        try? cancelled.apply(.driverAssigned(driverID: MockRideData.driver.id))
        try? cancelled.apply(.cancelled(date: now.addingTimeInterval(-3_000)))
        return [cancelled, completed]
    }
}
#endif
