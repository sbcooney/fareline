# Plan for #31: Let the driver cancel their current ride

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load `swift-testing-pro` for the domain, coding, service, and model tests
- [x] Load `swift-concurrency-pro` for `MockRideService.cancelRide(rideID:)` and its races with the rider's scheduled cancellation
- [x] Load `swiftui-pro`, with its navigation and accessibility references, for the control, the confirmation, and the Past Rides labels

## Phase 1: The domain records who cancelled

- [x] Write failing tests: a rider or driver can cancel while en route or at pickup; only a driver can cancel on trip; a cancelled ride records who cancelled and when; a rejected cancellation leaves the ride unchanged
- [x] Add `RideRole`, change `RideEvent.cancelled` to take `by:`, add `Ride.cancelledBy`, and update the transition table and its documentation. Update every caller, including test fixtures, previews, and `UITestLaunchOptions`
- [x] Write failing tests: a ride cancelled by each party round-trips through `Codable`; a driver's cancellation with no driver, and a completed ride with a canceller, are rejected when decoded; a cancelled ride saved without `cancelledBy` decodes as cancelled by the rider
- [x] Save and replay `cancelledBy` in `Ride+Codable`
- [x] Verify: the tests pass, and removing the role check from the on-trip transition makes its test fail

## Phase 2: The service cancels for the driver

- [x] Write failing tests: `cancelRide(rideID:)` at each stage ends the ride, saves it, frees the driver, and schedules the next offer; a wrong or ended ride throws `rideNoLongerAvailable`; a forced failure leaves everything unchanged; a rider's scheduled cancellation after the driver's has no effect; a rider cancelling at pickup ends the ride (the missing service test)
- [x] Add `cancelRide(rideID:)` to `RideService` and `MockRideService`
- [x] Verify: the tests pass. Recording the rider as the canceller, or leaving out the next offer, each makes tests fail. Stopping the rider's scheduled cancellation is shared with completing a trip, through `endActiveRide()`, and a late rider cancellation fails anyway, so no test can tell whether it was stopped

## Phase 3: The model cancels and picks the right alert

- [x] Write failing tests: `cancelRide(rideID:)` ends the ride with no alert; a failure shows the error and keeps the ride; a rider cancellation that wins the race shows only the rider-cancelled alert; a step for a ride the driver cancelled shows its error; a failed cancellation is covered by `DriverModelFailureTests`. A request in progress blocking any other action is already covered by `secondTapIsIgnoredWhileARequestIsInProgress`
- [x] Add `DriverModel.cancelRide(rideID:)`, and show the rider-cancelled alert only for rides the rider cancelled
- [x] Verify: the tests pass, and checking `status == .cancelled` instead of `cancelledBy == .rider`, in either place, makes a test fail

## Phase 4: The control and the confirmation

- [x] Write failing tests: the confirmation message for each stage, as a display property beside `RideStatus.title`
- [x] Add a Ride Options menu at the top right with Cancel Ride in it, and `confirmationDialog` attached to the menu, disabled during any request. (A Cancel Ride button below the step button came first. It was moved after review, as it sat too close to the step button and was too prominent.)
- [x] Verify: the unit tests and the current ride audit pass; screenshots of the screen, the open menu, and the confirmation in the simulator, taken by a temporary UI test that wasn't kept. UI tests of the confirmation were written and then removed: they needed a coordinate tap and audit exceptions, and the screenshots show the same thing

## Phase 5: Past Rides shows who cancelled

- [x] Write failing tests: the label for each canceller
- [x] Show the label in `PastRideRow` and `PastRideDetailView`, and seed a ride the driver cancelled for UI tests, so the Past Rides audits cover both labels
- [x] Verify: a screenshot of Past Rides with a ride cancelled by each party

## Before the PR

- [x] Review with `swift-testing-pro` (every new and changed test file)
- [x] Review with `swift-concurrency-pro` (`MockRideService.swift`, `DriverModel.swift`)
- [x] Review with `swiftui-pro` (`CurrentRideView`, `RideOptionsMenu`, `RideStepButton`, `PastRideRow`, `PastRideDetailView`)
- [x] `swiftlint lint` reports no violations
- [x] Run `/code-review`, and fix or record each finding
- [x] Update docs/PLAN.md: the status table's new order (#31 next, then the extended features, then #10 just before #17), with the reason in the decision log, the decision log entries for this track, the assumption "A rider can cancel until the trip starts", and the ride lifecycle in "Domain". The README has no assumptions section until #10 writes it, which picks up the new assumption from docs/PLAN.md
