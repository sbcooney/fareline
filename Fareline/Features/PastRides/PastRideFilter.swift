import Foundation

/// Which past rides the driver chooses to see.
///
/// Past Rides opens on ``completed``, the rides the driver was paid for. Each row of a cancelled ride already says
/// who cancelled, so ``cancelled`` covers both parties.
enum PastRideFilter: CaseIterable {
    case all
    case completed
    case cancelled

    /// Whether a past ride belongs in the list while this filter is on.
    func matches(_ ride: Ride) -> Bool {
        switch self {
        case .all:
            true
        case .completed:
            ride.status == .completed
        case .cancelled:
            ride.status == .cancelled
        }
    }

    /// The choice's name in the filter menu.
    var title: LocalizedStringResource {
        switch self {
        case .all:
            "All Rides"
        case .completed:
            "Completed"
        case .cancelled:
            "Cancelled"
        }
    }

    /// The empty state's title when rides exist but none match.
    ///
    /// All Rides never uses it, as it matches every ride, and Past Rides with no rides at all has its own empty
    /// state.
    var noMatchTitle: LocalizedStringResource {
        switch self {
        case .all:
            "No Past Rides"
        case .completed:
            "No Completed Rides"
        case .cancelled:
            "No Cancelled Rides"
        }
    }

    /// How many rides are showing out of the driver's whole history, such as "3 of 8 rides".
    ///
    /// The project has no String Catalog yet, so the singular is chosen here. It agrees with the total, which is
    /// the noun being counted.
    static func countDescription(showing shown: Int, of total: Int) -> LocalizedStringResource {
        total == 1 ? "\(shown) of \(total) ride" : "\(shown) of \(total) rides"
    }

    /// What VoiceOver says when the driver changes the filter, so they know what the list shows now.
    func announcement(showing count: Int) -> LocalizedStringResource {
        switch (self, count) {
        case (.all, 1):
            "Showing 1 ride"
        case (.all, _):
            "Showing all \(count) rides"
        case (.completed, 0):
            "No completed rides"
        case (.completed, 1):
            "Showing 1 completed ride"
        case (.completed, _):
            "Showing \(count) completed rides"
        case (.cancelled, 0):
            "No cancelled rides"
        case (.cancelled, 1):
            "Showing 1 cancelled ride"
        case (.cancelled, _):
            "Showing \(count) cancelled rides"
        }
    }
}
