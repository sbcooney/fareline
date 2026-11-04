# Plan for #12 and #13: See a queue of waiting riders, and self-assign to a ride

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load `swift-testing-pro` for the session, service, model, and display tests
- [x] Load `swift-concurrency-pro` for the list's timer in `MockRideService`, and the claim's races with offers, other drivers, and rider cancellations
- [x] Load `swiftui-pro`, with its navigation, data, and accessibility references, for the Waiting Riders screen, its rows, and the home screen's toolbar

## Phase 1: Passed-over rides join the list

- [x] Write failing tests: an offered ride isn't in the list; a ride joins the list when its offer is declined, expires, or ends because the driver goes offline; the list is longest wait first; a ride leaves the list when another driver takes it or its rider cancels; a ride in the list isn't offered again
- [x] Add `DriverSession.waitingRides`, and the service's record of passed-over rides, filled on decline and expiry. Update every place that makes a session, including test fixtures and previews
- [x] Verify: the tests pass, and sorting the list the wrong way, or leaving out the expiry case, each makes a test fail

## Phase 2: A driver's cancellation re-lists the rider, and the demo list changes

- [x] Write failing tests: cancelling while heading to pickup, and at pickup, each adds a request for the same rider, places, and fare, with the original request time and a new ID; the past ride stays cancelled by the driver; cancelling on trip adds nothing; the seeded rides start in the list with past request times; a passed-over request arrives after the interval, and none beyond the limit
- [x] Re-list the rider in `cancelRide(rideID:)` before the trip. Seed the list through a `waitingRides` parameter on `MockRideService`'s initializer, filled by `MockRideData.passedOverRides(at:)` in the app. Add `passedOverInterval` and `maximumWaitingRides` to `MockRideServiceConfiguration`, and add the timer
- [x] Verify: the tests pass, including the existing offer, expiry, and cancellation tests. Re-listing on trip, or giving the new request the current time, each makes a test fail. The timer stopping when the driver goes offline has no test: a timer that kept running would wake after the test's check, so the test would pass either way. It's checked by reading the code, as with the rider's scheduled cancellation in #31

## Phase 3: The service lets the driver claim a ride

- [x] Write failing tests: claiming a waiting ride makes it active, sets the driver on a ride, removes it from the list, and schedules the rider's cancellation; claiming while offline or on a ride is refused; claiming a ride that isn't in the list, such as the offered one, fails; claiming while an offer is pending declines the offer and lists its ride; a forced failure changes nothing; a ride another driver took, or whose rider cancelled, fails with `rideNoLongerWaiting`; claiming Taylor Taken's ride fails as taken
- [x] Add `rideNoLongerWaiting` and its message, `claimRide(rideID:)` to `RideService` and `MockRideService`, and Taylor Taken to the mock data
- [x] Verify: the tests pass. Leaving out the list check, or the offer's decline, each makes a test fail

## Phase 4: The model claims rides

- [x] Write failing tests: `claimRide(rideID:)` starts the ride; a conflict shows the new error, and the ride is gone from the model's list; a new offer, during the request or after, doesn't hide the conflict's message (found when the user's tap on Taylor Taken seemed to do nothing); an offer declined by claiming isn't reported as unanswered; a failed claim is covered by `DriverModelFailureTests`
- [x] Add `DriverModel.claimRide(rideID:)`, marking a pending offer as answered when the claim declines it
- [x] Verify: the tests pass, and removing the answered mark makes the VoiceOver test fail

## Phase 5: The Waiting Riders screen

- [x] Write failing tests: the wait time's text for waits under a minute, which never shows "0 minutes", a few minutes, and over an hour, in `RideDisplayTests`
- [x] Add `AppDestination.waitingRiders`, `WaitingRidersView` and `WaitingRideRow`, and the home screen's toolbar button. Rows show pickup, drop-off, fare, and wait time, redrawn once a minute, with a Take Ride button enabled only while available and no request is in progress. The empty state says no one is waiting, and offline shows a line to go online to take a ride
- [ ] No unit test for the screen itself, which is view state. Verify: the user runs the app and checks the screen opens from home, rows update as rides arrive and leave, Take Ride starts the ride, a cancelled ride's rider reappears, Taylor Taken shows the conflict message, and the empty and offline states read correctly. No UI tests, per CLAUDE.md

## Before the PR

- [ ] Review with `swift-testing-pro` (every new and changed test file)
- [ ] Review with `swift-concurrency-pro` (`MockRideService.swift`, `DriverModel.swift`)
- [ ] Review with `swiftui-pro` (`WaitingRidersView`, `WaitingRideRow`, the home screen's toolbar in `RootView`, `AppDestination`)
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md:
  - Status: #12 and #13 done; #11 and #14 ➖, with #23 added as ➖, all folded into #10; rows added for #33 and #34
  - Decision log: doing #12 and #13 together; describing the map, the drivers list, and status outside the app in the README rather than building them; the two decided items in the spec; this track's other decisions
  - Domain: the list of rides no driver took, and a driver's cancellation re-listing the rider
  - The skills table: "Map and queues" becomes #12's queue
  - Assumptions: anything new, such as a fixed limit on waiting riders
