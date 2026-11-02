import Foundation

/// Provides the current time and waiting, so that tests can control time rather than wait for it.
///
/// This is used instead of the standard `Clock` protocol because domain rules work in `Date`s.
protocol TimeSource: Sendable {
    /// The current time.
    var now: Date { get }

    /// Suspends until the given time.
    ///
    /// This takes an absolute time rather than a duration, so the result doesn't depend on exactly when
    /// the waiting task begins to run.
    ///
    /// - Throws: `CancellationError` if the task is cancelled while waiting.
    func sleep(until date: Date) async throws
}
