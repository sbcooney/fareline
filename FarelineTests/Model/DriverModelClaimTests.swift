import Foundation
import Testing
@testable import Fareline

/// Covers the driver taking a ride from the waiting list, including when someone else gets there first.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DriverModelClaimTests {
    private let time = ManualTimeSource()
    private let ride = TestFixtures.ride()

    /// Returns a model whose driver is online, with the given rides in the waiting list.
    private func makeOnlineModel(waitingRides: [Ride]) async -> (MockRideService, DriverModel) {
        let service = MockRideService(
            configuration: MockRideServiceConfiguration(offerDelay: nil, offerLifetime: 30, responseDelay: 0),
            timeSource: time,
            driver: Driver(id: TestFixtures.driverID, name: PersonNameComponents()),
            waitingRides: waitingRides
        )
        let model = DriverModel(service: service)
        await model.goOnline()
        return (service, model)
    }

    @Test func claimingStartsTheRide() async throws {
        let (_, model) = await makeOnlineModel(waitingRides: [ride])

        await model.claimRide(rideID: ride.id)

        #expect(model.session?.activeRide?.id == ride.id)
        #expect(model.session?.waitingRides.isEmpty == true)
        #expect(model.alert == nil)
    }

    @Test func rideTakenByAnotherDriverShowsWhyAndLeavesTheList() async throws {
        let seeded = MockRideData.passedOverRides(at: time.now)
        let taylor = try #require(seeded.first { MockRideData.isTakenByAnotherDriverWhenClaimed($0) })
        let (_, model) = await makeOnlineModel(waitingRides: seeded)
        let updates = Task { await model.start() }
        defer { updates.cancel() }

        await model.claimRide(rideID: taylor.id)
        await waitUntil { model.session?.waitingRides.contains { $0.id == taylor.id } == false }

        #expect(model.alert == .error(.rideNoLongerWaiting))
        #expect(model.session?.activeRide == nil)
    }

    @Test func newOfferKeepsTheConflictMessage() async throws {
        let seeded = MockRideData.passedOverRides(at: time.now)
        let taylor = try #require(seeded.first { MockRideData.isTakenByAnotherDriverWhenClaimed($0) })
        let (service, model) = await makeOnlineModel(waitingRides: seeded)
        let updates = Task { await model.start() }
        defer { updates.cancel() }
        await model.claimRide(rideID: taylor.id)
        try #require(model.alert == .error(.rideNoLongerWaiting))

        await service.addRide(ride)
        try await service.offerRide(id: ride.id)
        await waitUntil { model.session?.pendingOffer != nil }

        // The message says the rider is no longer waiting, so it can't be mistaken for one about the new offer.
        #expect(model.alert == .error(.rideNoLongerWaiting))
    }

    @Test func offerArrivingDuringTheClaimKeepsTheConflictMessage() async throws {
        let seeded = MockRideData.passedOverRides(at: time.now)
        let taylor = try #require(seeded.first { MockRideData.isTakenByAnotherDriverWhenClaimed($0) })
        let service = MockRideService(
            configuration: MockRideServiceConfiguration(offerDelay: nil, offerLifetime: 30, responseDelay: 1),
            timeSource: time,
            driver: Driver(id: TestFixtures.driverID, name: PersonNameComponents()),
            waitingRides: seeded
        )
        let model = DriverModel(service: service)
        let updates = Task { await model.start() }
        defer { updates.cancel() }
        let goingOnline = Task { await model.goOnline() }
        await time.waitForSleeper()
        time.advance(by: 1)
        await goingOnline.value

        let claiming = Task { await model.claimRide(rideID: taylor.id) }
        await time.waitForSleeper()
        await service.addRide(ride)
        try await service.offerRide(id: ride.id)
        await waitUntil { model.session?.pendingOffer != nil }
        // The offer's expiry is also waiting now, and only the claim's delay needs to end.
        time.advance(by: 1)
        await claiming.value

        #expect(model.alert == .error(.rideNoLongerWaiting))
    }

    @Test func offerArrivingDuringAClaimIsntReportedAsUnanswered() async throws {
        let service = MockRideService(
            configuration: MockRideServiceConfiguration(offerDelay: nil, offerLifetime: 30, responseDelay: 1),
            timeSource: time,
            driver: Driver(id: TestFixtures.driverID, name: PersonNameComponents()),
            waitingRides: [ride]
        )
        let offered = Ride(
            id: UUID(testValue: 41),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        let model = DriverModel(service: service)
        let updates = Task { await model.start() }
        defer { updates.cancel() }
        let goingOnline = Task { await model.goOnline() }
        await time.waitForSleeper()
        time.advance(by: 1)
        await goingOnline.value

        let claiming = Task { await model.claimRide(rideID: ride.id) }
        await time.waitForSleeper()
        await service.addRide(offered)
        try await service.offerRide(id: offered.id)
        await waitUntil { model.session?.pendingOffer != nil }
        time.advance(by: 1)
        await claiming.value

        // The claim ended the offer, so it was the driver's choice rather than an offer left unanswered.
        #expect(model.session?.activeRide?.id == ride.id)
        #expect(model.unansweredOfferID == nil)
    }

    @Test func offerDeclinedByClaimingIsntReportedAsUnanswered() async throws {
        let offered = Ride(
            id: UUID(testValue: 40),
            rider: ride.rider,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            fare: ride.fare,
            requestedAt: time.now
        )
        let (service, model) = await makeOnlineModel(waitingRides: [ride])
        await service.addRide(offered)
        try await service.offerRide(id: offered.id)
        model.apply(try await service.currentSession())

        await model.claimRide(rideID: ride.id)

        // The driver chose another ride, so VoiceOver shouldn't announce that the offer ended without an answer.
        #expect(model.unansweredOfferID == nil)
        #expect(model.session?.activeRide?.id == ride.id)
    }
}
