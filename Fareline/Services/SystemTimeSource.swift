import Foundation

/// A time source that uses the real system time.
struct SystemTimeSource: TimeSource {
    var now: Date { .now }

    func sleep(until date: Date) async throws {
        try await Task.sleep(for: .seconds(date.timeIntervalSince(.now)))
    }
}
