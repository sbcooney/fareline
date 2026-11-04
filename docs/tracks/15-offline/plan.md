# Plan for #15: Offline capability

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load `swift-testing-pro` for the service, model, and display tests
- [x] Load `swift-concurrency-pro`, with its actors, async-streams, and testing references, for the mock's held-back updates and replaying the queue in order
- [x] Load `swiftui-pro`, with its accessibility and views references, for the offline banner, the disabled controls, and the demo menu
- [x] Propose the new names, and wait for the user's decision

## Phase 1: Connectivity and the offline banner

- [x] Write failing tests: requests fail with `networkUnavailable` while disconnected and change nothing; the stream sends nothing while disconnected, then the latest session on reconnecting; the banner's text with none, one, and several steps waiting
- [x] Add the connectivity switch to `MockRideService`, the model's offline state, the banner, and the demo menu, on every main screen
- [ ] Verify: the tests pass, and requests ignoring the connection, or reconnecting without sending the latest session, each makes a test fail. Sending sessions while disconnected can't be told apart by a test, as the stream keeps only the newest snapshot, so it's checked by reading the code. The user checks the banner and its VoiceOver announcements in the app

## Phase 2: Live actions are disabled offline

- [ ] Write failing tests: actions that need a connection are refused offline without a request
- [ ] Disable those controls offline, with a line saying they need a connection
- [ ] Verify: the tests pass, and the user checks the current ride, Past Rides, and Waiting Riders offline in the app

## Phase 3: Ride steps queue and replay

- [ ] Write failing tests: a step offline updates the ride on screen and queues without a request; steps replay in order; a step not allowed from the ride's status is refused; the queue empties after replay; a rejected step drops the rest and tells the driver; a rider's cancellation shows the rider-cancelled alert instead; a network failure during replay keeps the queue
- [ ] Add the model's queue and replay on reconnecting, and the time of the tap to `completeTrip` and `cancelRide`, if decided
- [ ] Verify: the tests pass, and replaying out of order, or not dropping the queue after a rejection, each makes a test fail. The user checks a ride completed offline, and Will Cancel cancelling while offline, in the app

## Before the PR

- [ ] Review with `swift-testing-pro` (every new and changed test file)
- [ ] Review with `swift-concurrency-pro` (`MockRideService.swift`, `DriverModel.swift`)
- [ ] Review with `swiftui-pro` (the offline banner, the demo menu, and every view whose controls are disabled offline)
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Add a "Simulating no connection" section to the README: where the Demo menu is, what it does, and a walk-through of a ride completed offline
- [ ] Update docs/PLAN.md: #15's status, the decision log entries for this track, the assumptions it adds, the architecture note that the model now holds queued steps, and the open question about #15, now answered
