import Foundation
import Synchronization
import Testing
@testable import Fareline

/// Covers sending one stream's values to every subscriber.
@Suite(.timeLimit(.minutes(1)))
struct SubscriberListTests {
    private var subscribers = SubscriberList<Int>()

    @Test mutating func startsWithTheInitialValue() async {
        var stream = subscribers.add(startingWith: 1) { _ in }.makeAsyncIterator()

        #expect(await stream.next() == 1)
    }

    @Test mutating func sendsToEverySubscriber() async {
        var first = subscribers.add(startingWith: nil) { _ in }.makeAsyncIterator()
        var second = subscribers.add(startingWith: nil) { _ in }.makeAsyncIterator()

        subscribers.send(2)

        #expect(await first.next() == 2)
        #expect(await second.next() == 2)
    }

    @Test mutating func keepsOnlyTheNewestUnreadValue() async {
        var stream = subscribers.add(startingWith: 1) { _ in }.makeAsyncIterator()

        subscribers.send(2)
        subscribers.send(3)

        #expect(await stream.next() == 3)
    }

    @Test mutating func endingAStreamReportsItsIDForRemoval() {
        let endedIDs = Mutex<[UUID]>([])

        // Discarding a stream ends it.
        _ = subscribers.add(startingWith: nil) { id in
            endedIDs.withLock { $0.append(id) }
        }

        #expect(endedIDs.withLock { $0.count } == 1)
    }

    @Test mutating func finishingEndsEveryStream() async {
        var first = subscribers.add(startingWith: nil) { _ in }.makeAsyncIterator()
        var second = subscribers.add(startingWith: nil) { _ in }.makeAsyncIterator()

        subscribers.finishAll()

        #expect(await first.next() == nil)
        #expect(await second.next() == nil)
    }
}
