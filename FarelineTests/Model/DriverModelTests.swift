import Foundation
import Testing
@testable import Fareline

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()

    private func makeService(responseDelay: TimeInterval = 0) -> MockRideService {
        .forModelTests(time: time, responseDelay: responseDelay)
    }

    /// Returns a model whose driver has a pending offer for the fixture ride.
    private func makeModelWithOffer(service: MockRideService) async throws -> DriverModel {
        let model = DriverModel(service: service)
        await service.addRide(ride)
        model.apply(try await service.goOnline())
        try await service.offerRide(id: ride.id)
        for await session in await service.sessionUpdates() {
            model.apply(session)
            break
        }
        return model
    }

    private func acceptCurrentOffer(in model: DriverModel) async {
        guard let id = model.session?.pendingOffer?.id else {
            Issue.record("Expected a pending offer.")
            return
        }
        await model.acceptOffer(id: id)
    }

    private func makeSession(version: Int) -> DriverSession {
        DriverSession(
            version: version,
            driver: Driver(id: TestFixtures.driverID, name: PersonNameComponents()),
            pendingOffer: nil,
            activeRide: nil,
            pastRides: [],
            waitingRides: []
        )
    }

    @Test func startReceivesSessionsFromTheService() async {
        let model = DriverModel(service: makeService())

        let task = Task { await model.start() }
        await waitUntil { model.session != nil }
        task.cancel()

        #expect(model.session?.driver.availability == .offline)
    }

    @Test func goingOnlineUpdatesTheSession() async {
        let model = DriverModel(service: makeService())

        await model.goOnline()

        #expect(model.session?.driver.availability == .available)
        #expect(model.alert == nil)
    }

    @Test func acceptingUpdatesTheSession() async throws {
        let model = try await makeModelWithOffer(service: makeService())

        await acceptCurrentOffer(in: model)

        #expect(model.session?.pendingOffer == nil)
        #expect(model.session?.activeRide?.id == ride.id)
        #expect(model.session?.driver.availability == .onRide)
    }

    @Test func decliningClearsTheOfferAndLeavesTheRideAvailable() async throws {
        let service = makeService()
        let model = try await makeModelWithOffer(service: service)

        await model.declineOffer(id: try #require(model.session?.pendingOffer?.id))

        #expect(model.session?.pendingOffer == nil)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }

    @Test func failedRequestKeepsTheSessionAndRecordsTheError() async throws {
        let service = makeService()
        let model = try await makeModelWithOffer(service: service)
        let original = model.session
        await service.failNextRequest(with: .networkUnavailable)

        await acceptCurrentOffer(in: model)

        #expect(model.session == original)
        #expect(model.alert == .error(.networkUnavailable))
        #expect(model.isPerformingAction == false)
    }

    @Test func nextActionClearsThePreviousError() async throws {
        let service = makeService()
        let model = try await makeModelWithOffer(service: service)
        await service.failNextRequest(with: .networkUnavailable)
        await acceptCurrentOffer(in: model)

        await acceptCurrentOffer(in: model)

        #expect(model.alert == nil)
        #expect(model.session?.activeRide?.id == ride.id)
    }

    @Test func olderSessionIsIgnored() {
        let model = DriverModel(service: makeService())

        model.apply(makeSession(version: 5))
        model.apply(makeSession(version: 3))

        #expect(model.session?.version == 5)
    }

    @Test func secondTapIsIgnoredWhileARequestIsInProgress() async throws {
        let service = makeService(responseDelay: 1)
        let model = DriverModel(service: service)

        let firstTap = Task { await model.goOnline() }
        await waitUntil { model.isPerformingAction }

        // A second request would fail, as the driver can't go online twice, and record an error.
        await model.goOnline()
        #expect(model.isPerformingAction)

        await time.waitForSleeper()
        time.advance(by: 1)
        await firstTap.value

        #expect(model.session?.driver.availability == .available)
        #expect(model.alert == nil)
    }

    @Test func acceptingAnOfferThatIsNoLongerCurrentDoesntTakeTheNewOne() async throws {
        let service = makeService()
        let model = try await makeModelWithOffer(service: service)
        let staleID = UUID(testValue: 20)
        let original = model.session

        await model.acceptOffer(id: staleID)

        #expect(model.alert == .error(.offerNoLongerAvailable))
        #expect(model.session == original)
        #expect(await service.ride(id: ride.id)?.status == .awaitingDriver)
    }
}
