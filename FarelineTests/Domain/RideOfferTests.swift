import Foundation
import Testing
@testable import Fareline

struct RideOfferTests {
    private let beforeExpiry: Date
    private let atExpiry: Date

    init() {
        let offer = TestFixtures.offer()
        atExpiry = offer.expiresAt
        beforeExpiry = offer.expiresAt.addingTimeInterval(-1)
    }

    @Test func newOfferIsPending() {
        #expect(TestFixtures.offer().status == .pending)
    }

    @Test func driverCanAcceptBeforeExpiry() throws {
        var offer = TestFixtures.offer()

        try offer.accept(at: beforeExpiry)

        #expect(offer.status == .accepted)
    }

    @Test func driverCanDeclineBeforeExpiry() throws {
        var offer = TestFixtures.offer()

        try offer.decline(at: beforeExpiry)

        #expect(offer.status == .declined)
    }

    /// Covers a tap that arrives just as the countdown ends.
    @Test func responseAtExpiryIsTooLate() {
        var offer = TestFixtures.offer()

        #expect(throws: RideOfferError.responseTooLate) {
            try offer.accept(at: atExpiry)
        }
        #expect(throws: RideOfferError.responseTooLate) {
            try offer.decline(at: atExpiry)
        }
        #expect(offer.status == .pending)
    }

    @Test func offerExpiresAtItsExpiryTime() throws {
        var offer = TestFixtures.offer()

        try offer.expire(at: atExpiry)

        #expect(offer.status == .expired)
    }

    @Test func offerCantExpireEarly() {
        var offer = TestFixtures.offer()

        #expect(throws: RideOfferError.notYetExpired) {
            try offer.expire(at: beforeExpiry)
        }
        #expect(offer.status == .pending)
    }

    @Test func resolvedOfferRejectsFurtherChanges() throws {
        var offer = TestFixtures.offer()
        try offer.accept(at: beforeExpiry)

        #expect(throws: RideOfferError.alreadyResolved(.accepted)) {
            try offer.decline(at: beforeExpiry)
        }
        #expect(throws: RideOfferError.alreadyResolved(.accepted)) {
            try offer.expire(at: atExpiry)
        }
        #expect(offer.status == .accepted)
    }
}
