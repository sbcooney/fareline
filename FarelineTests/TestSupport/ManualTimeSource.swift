import Foundation
import Synchronization
@testable import Fareline

/// A time source that only moves forward when a test tells it to, so tests never wait for real time.
final class ManualTimeSource: TimeSource {
    private struct State {
        var now: Date
        var sleepers: [UUID: Sleeper] = [:]
    }

    private struct Sleeper {
        let date: Date
        let continuation: CheckedContinuation<Void, any Error>
    }

    private let state: Mutex<State>

    init(now: Date = TestFixtures.date) {
        state = Mutex(State(now: now))
    }

    var now: Date {
        state.withLock { $0.now }
    }

    func sleep(until date: Date) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                register(id: id, date: date, continuation: continuation)
            }
        } onCancel: {
            cancel(id: id)
        }
    }

    private func register(id: UUID, date: Date, continuation: CheckedContinuation<Void, any Error>) {
        state.withLock { (state: inout State) in
            if Task.isCancelled {
                continuation.resume(throwing: CancellationError())
            } else if date <= state.now {
                continuation.resume()
            } else {
                state.sleepers[id] = Sleeper(date: date, continuation: continuation)
            }
        }
    }

    private func cancel(id: UUID) {
        state.withLock { (state: inout State) in
            state.sleepers.removeValue(forKey: id)?.continuation.resume(throwing: CancellationError())
        }
    }

    /// Waits until at least the given number of things are sleeping.
    ///
    /// Tests call this before ``advance(by:)`` when the sleeper's deadline is based on the current time,
    /// because advancing first would move that deadline as well.
    func waitForSleeper(count: Int = 1) async {
        while state.withLock({ $0.sleepers.count < count }) {
            await Task.yield()
        }
    }

    /// Moves time forward and wakes anything whose wait has finished.
    func advance(by interval: TimeInterval) {
        state.withLock { state in
            state.now = state.now.addingTimeInterval(interval)
            let now = state.now
            for (id, sleeper) in state.sleepers where sleeper.date <= now {
                state.sleepers[id] = nil
                sleeper.continuation.resume()
            }
        }
    }
}
