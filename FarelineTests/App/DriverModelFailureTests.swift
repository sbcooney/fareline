import Foundation
import Testing
@testable import Fareline

/// Covers what the driver sees after any action fails: a message, the same state, and a control they
/// can tap again.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelFailureTests {
    /// Each action a driver can take, so one test can cover them all.
    enum Action: CaseIterable {
        case goOnline, goOffline, accept, decline, markArrived, startTrip, completeTrip, cancelRide
    }

    /// Performs the action being tested.
    typealias Perform = () async -> Void

    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()
    private let service: MockRideService
    private let model: DriverModel

    init() {
        service = .forModelTests(time: time)
        model = DriverModel(service: service)
    }

    /// Puts the driver in the state where the action is allowed, and returns how to perform it.
    private func prepare(_ action: Action) async throws -> Perform {
        let rideID = ride.id
        switch action {
        case .goOnline:
            model.apply(try await service.currentSession())
            return { await model.goOnline() }
        case .goOffline:
            await model.goOnline()
            return { await model.goOffline() }
        case .accept, .decline:
            await service.addRide(ride)
            await model.goOnline()
            try await service.offerRide(id: rideID)
            model.apply(try await service.currentSession())
            let offerID = try #require(model.session?.pendingOffer?.id)
            return action == .accept
                ? { await model.acceptOffer(id: offerID) }
                : { await model.declineOffer(id: offerID) }
        case .markArrived, .startTrip, .completeTrip, .cancelRide:
            await service.addRide(ride)
            await model.goOnline()
            try await service.offerRide(id: rideID)
            model.apply(try await service.currentSession())
            await model.acceptOffer(id: try #require(model.session?.pendingOffer?.id))
            if action == .cancelRide {
                return { await model.cancelRide(rideID: rideID) }
            }
            if action == .markArrived {
                return { await model.markArrived(rideID: rideID) }
            }
            await model.markArrived(rideID: rideID)
            if action == .startTrip {
                return { await model.startTrip(rideID: rideID) }
            }
            await model.startTrip(rideID: rideID)
            return { await model.completeTrip(rideID: rideID) }
        }
    }

    @Test(arguments: Action.allCases)
    func failedActionKeepsTheStateAndCanBeRetried(_ action: Action) async throws {
        let perform = try await prepare(action)
        let original = model.session
        await service.failNextRequest(with: .networkUnavailable)

        await perform()

        #expect(model.alert == .error(.networkUnavailable))
        #expect(model.session == original)
        #expect(model.isPerformingAction == false)

        await perform()
        #expect(model.alert == nil)
        #expect(model.session != original)
    }

    @Test(arguments: [
        RideServiceError.networkUnavailable,
        .offerNoLongerAvailable,
        .rideNoLongerAvailable,
        .actionNotAllowed
    ])
    func everyErrorHasAMessage(_ error: RideServiceError) {
        #expect(String(localized: DriverAlert.error(error).message).isEmpty == false)
    }
}
