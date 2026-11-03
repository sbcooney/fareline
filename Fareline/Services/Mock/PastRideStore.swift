import Foundation

/// Saves the driver's past rides to a JSON file, so they survive relaunching the app.
///
/// `MockRideService` uses this in place of the database a real backend would keep history in.
struct PastRideStore: Sendable {
    /// The file the rides are saved in.
    let fileURL: URL

    /// The store the app uses, in Application Support.
    static let app = PastRideStore(fileURL: .applicationSupportDirectory.appending(path: "PastRides.json"))

    /// Returns the saved rides, newest first, or none if there's no file or it can't be read.
    ///
    /// A file with any ride that hasn't ended, or has no driver, is rejected as a whole. That keeps the
    /// rule simple, at the cost of hiding the valid rides in a damaged file. The file isn't changed here, so
    /// it's only replaced when the next ride ends.
    func load() -> [Ride] {
        guard let data = try? Data(contentsOf: fileURL),
              let rides = try? JSONDecoder().decode([Ride].self, from: data),
              rides.allSatisfy({ $0.endedAt != nil && $0.driverID != nil }) else {
            return []
        }
        return rides
    }

    /// Replaces the saved rides.
    func save(_ rides: [Ride]) throws {
        let data = try JSONEncoder().encode(rides)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        // Writing atomically means a crash mid-save leaves the previous file rather than a partial one.
        try data.write(to: fileURL, options: .atomic)
    }
}
