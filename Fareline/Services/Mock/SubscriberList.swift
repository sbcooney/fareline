import Foundation

/// Everyone receiving one of the mock's streams, so it can send each of them the same values.
///
/// Each stream keeps only the newest unread value, because every value replaces the one before it, such as a whole
/// session or the connection's current state.
struct SubscriberList<Element: Sendable> {
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    /// Adds a subscriber, and returns its stream.
    ///
    /// - Parameters:
    ///   - initial: A value the stream starts with, or `nil` for none yet.
    ///   - onTermination: Called with the subscriber's ID when its stream ends, so the owner can ``remove(id:)`` it.
    mutating func add(
        startingWith initial: Element?,
        onTermination: @escaping @Sendable (UUID) -> Void
    ) -> AsyncStream<Element> {
        let (stream, continuation) = AsyncStream.makeStream(of: Element.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { _ in onTermination(id) }
        if let initial {
            continuation.yield(initial)
        }
        return stream
    }

    mutating func remove(id: UUID) {
        continuations[id] = nil
    }

    func send(_ element: Element) {
        continuations.values.forEach { $0.yield(element) }
    }

    func finishAll() {
        continuations.values.forEach { $0.finish() }
    }
}
