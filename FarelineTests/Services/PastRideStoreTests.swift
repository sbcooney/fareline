import Foundation
import Testing
@testable import Fareline

/// A class, so that `deinit` can remove each test's folder.
final class PastRideStoreTests {
    private let folder = URL.temporaryDirectory.appending(path: "PastRideStoreTests-\(UUID().uuidString)")
    private let store: PastRideStore

    init() {
        store = PastRideStore(fileURL: folder.appending(path: "PastRides.json"))
    }

    deinit {
        try? FileManager.default.removeItem(at: folder)
    }

    @Test func missingFileStartsEmpty() {
        #expect(store.load().isEmpty)
    }

    @Test func savedRidesLoadBackUnchangedAndInOrder() throws {
        let cancelled = try TestFixtures.cancelledRide()
        let completed = try TestFixtures.completedRide()

        try store.save([cancelled, completed])

        #expect(store.load() == [cancelled, completed])
    }

    @Test func unreadableFileStartsEmptyAndIsLeftAlone() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let unreadable = Data("not JSON".utf8)
        try unreadable.write(to: store.fileURL)

        #expect(store.load().isEmpty)
        #expect(try Data(contentsOf: store.fileURL) == unreadable)
    }

    @Test func rideThatHasntEndedIsRejected() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.driverAssigned(driverID: TestFixtures.driverID))

        try store.save([try TestFixtures.completedRide(), ride])

        #expect(store.load().isEmpty)
    }

    @Test func pastRideWithNoDriverIsRejected() throws {
        var ride = TestFixtures.ride()
        try ride.apply(.cancelled(date: TestFixtures.date))

        try store.save([ride])

        #expect(store.load().isEmpty)
    }
}
