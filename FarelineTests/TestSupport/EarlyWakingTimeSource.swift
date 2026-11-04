import Foundation
import Synchronization
@testable import Fareline

/// A time source whose first wait ends immediately, as can happen when the system clock changes.
final class EarlyWakingTimeSource: TimeSource {
    private let base: ManualTimeSource
    private let hasWokenEarly = Mutex(false)

    init(base: ManualTimeSource) {
        self.base = base
    }

    var now: Date { base.now }

    func sleep(until date: Date) async throws {
        let wakesEarly = hasWokenEarly.withLock { hasWokenEarly in
            defer { hasWokenEarly = true }
            return hasWokenEarly == false
        }
        if wakesEarly == false {
            try await base.sleep(until: date)
        }
    }
}
