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

- [ ] Write failing tests: `cancelRide(rideID:)` at each stage ends the ride, saves it, frees the driver, and schedules the next offer; a wrong or ended ride throws `rideNoLongerAvailable`; a forced failure leaves everything unchanged; a driver's cancellation stops the rider's scheduled one; a rider cancelling at pickup ends the ride (the missing service test)
- [ ] Add `cancelRide(rideID:)` to `RideService` and `MockRideService`
- [ ] Verify: the tests pass, and leaving out the cancellation of the rider's scheduled task makes its test fail

## Phase 3: The model cancels and picks the right alert

- [ ] Write failing tests: `cancelRide(rideID:)` ends the ride with no alert; a failure shows the error and keeps the ride; a rider cancellation that wins the race shows only the rider-cancelled alert; a request in progress blocks a step
- [ ] Add `DriverModel.cancelRide(rideID:)`, and show the rider-cancelled alert only for rides the rider cancelled
- [ ] Verify: the tests pass, and dropping the `cancelledBy` check makes the no-alert test fail

## Phase 4: The control and the confirmation

- [ ] Write failing tests: the confirmation message for each stage, as a display property beside `RideStatus.title`
- [ ] Add the Cancel Ride button below the step button, with `confirmationDialog` attached to it, disabled during any request
- [ ] Write a UI test: open the confirmation, choose Keep Ride and see the ride unchanged, then confirm and see the available screen. Add an audit of the open confirmation
- [ ] Verify: the unit and UI tests pass; screenshots of each stage's confirmation in the simulator

## Phase 5: Past Rides shows who cancelled

- [ ] Write failing tests: the label for each canceller
- [ ] Show the label in `PastRideRow` and `PastRideDetailView`
- [ ] Verify: a screenshot of Past Rides with a ride cancelled by each party

## Before the PR

- [ ] Review with `swift-testing-pro` (every new and changed test file)
- [ ] Review with `swift-concurrency-pro` (`MockRideService.swift`, `DriverModel.swift`)
- [ ] Review with `swiftui-pro` (`CurrentRideView`, the new control, `PastRideRow`, `PastRideDetailView`)
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: the status table's new order (#31 next, then the extended features, then #10 just before #17), with the reason in the decision log, the decision log entries for this track, the assumption "A rider can cancel until the trip starts", the ride lifecycle in "Domain", and the README's assumptions
