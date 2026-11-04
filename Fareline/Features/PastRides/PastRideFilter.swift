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
    /// The String Catalog has the singular, which agrees with the total, as that's the noun being counted.
    static func countDescription(showing shown: Int, of total: Int) -> LocalizedStringResource {
        "\(shown) of \(total) rides"
    }

    /// What VoiceOver says when the driver changes the filter, so they know what the list shows now. The String
    /// Catalog has the singulars.
    func announcement(showing count: Int) -> LocalizedStringResource {
        switch (self, count) {
        case (.all, 0):
            "No past rides"
        case (.all, _):
            "Showing all \(count) rides"
        case (.completed, 0):
            "No completed rides"
        case (.completed, _):
            "Showing \(count) completed rides"
        case (.cancelled, 0):
            "No cancelled rides"
        case (.cancelled, _):
            "Showing \(count) cancelled rides"
        }
    }
}
