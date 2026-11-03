import Foundation
import os

/// Saves the driver's past rides to a JSON file, so they survive relaunching the app.
///
/// `MockRideService` uses this in place of the database a real backend would keep history in.
struct PastRideStore: Sendable {
    /// The file the rides are saved in.
    let fileURL: URL

    /// Where an unreadable file is moved, next to ``fileURL``.
    var unreadableFileURL: URL {
        fileURL.deletingPathExtension().appendingPathExtension("unreadable.json")
    }

    /// The store the app uses, in Application Support.
    static let app = PastRideStore(fileURL: .applicationSupportDirectory.appending(path: "PastRides.json"))

    private static let logger = Logger(subsystem: "com.sbcooney.Fareline", category: "PastRideStore")

    /// Returns the saved rides, newest first, or none if there's no file or it can't be read.
    ///
    /// A file with any ride that hasn't ended, or has no driver, is rejected as a whole. That keeps the
    /// rule simple, at the cost of hiding the valid rides in a damaged file. A rejected file is moved to
    /// ``unreadableFileURL``, replacing any earlier one, so the next save can't overwrite the history it holds.
    func load() -> [Ride] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        do {
            let rides = try JSONDecoder().decode([Ride].self, from: data)
            guard rides.allSatisfy({ $0.endedAt != nil && $0.driverID != nil }) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return rides
        } catch {
            Self.logger.error("Couldn't read past rides, so the file was moved aside: \(error)")
            try? FileManager.default.removeItem(at: unreadableFileURL)
            try? FileManager.default.moveItem(at: fileURL, to: unreadableFileURL)
            return []
        }
    }

    /// Replaces the saved rides, logging any failure before throwing it.
    func save(_ rides: [Ride]) throws {
        do {
            let data = try JSONEncoder().encode(rides)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // Writing atomically means a crash mid-save leaves the previous file rather than a partial one.
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Self.logger.error("Couldn't save past rides: \(error)")
            throw error
        }
    }
}
