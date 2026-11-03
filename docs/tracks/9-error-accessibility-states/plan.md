# Plan for #9: Error, empty, and accessibility states

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work. The phases follow the decisions in the spec.

## Before starting

- [ ] Load `swiftui-pro`, with its accessibility, resizability, navigation, and views references
- [ ] Load `swift-testing-pro` for the model tests
- [ ] Measure today's problems first: screenshot every screen at the largest text size on iPhone 17e, iPhone 18 Pro Max, and iPhone Duo's outer display, so each later phase has a before and after

## Phase 1: One alert at a time

- [ ] Write failing tests: a cancellation replaces an error; an error doesn't replace a cancellation; no redundant "no longer available" after a dismissed cancellation; a new offer clears an error but not a cancellation; dismissing clears the alert
- [ ] Add `DriverAlert`, replace `lastError` and `cancelledRide` with `alert` on `DriverModel`, and present it with `alert(_:item:)` in `RootView`
- [ ] Update the existing tests that check `lastError` or `cancelledRide`
- [ ] Verify: the tests pass, and removing each precedence rule fails its test

## Phase 2: Failures and empty states

- [ ] Write failing tests: every `RideServiceError` has a message; after each kind of failed action, the control is enabled and the state unchanged
- [ ] Fix anything the tests find
- [ ] Verify: the tests pass, and simulator screenshots of Connecting, Past Rides with no rides, and a missing past ride

## Phase 3: Offers without pulling the driver away

- [ ] Write a failing test: the model reports an offer that ended without the driver responding, and not one they accepted or declined
- [ ] Add that to `DriverModel`
- [ ] No unit test for the views: add `OfferBanner` over pushed screens, opening the offer on tap, and remove the path clearing from `RootView`. A ride starting still clears the path
- [ ] Announce an offer's arrival and end with VoiceOver, and add haptic feedback on arrival
- [ ] Verify: in the simulator, an offer on Past Rides shows the banner and leaves the driver there; tapping it opens the offer; it disappears when the offer ends; with Reduce Motion on, it fades

## Phase 4: Taps that can't land by accident

- [ ] No unit test: the delay is view timing. Make Accept, Decline, and Go Offline ignore taps for 0.75 seconds after they appear, looking disabled and announced as unavailable until ready
- [ ] Verify: in the simulator, a tap right after an offer appears or ends does nothing, and one after the delay works

## Phase 5: Labels, text sizes, and iPhone sizes

- [ ] Add the `FarelineUITests` target, with launch arguments that open each screen, and a test per screen that calls `performAccessibilityAudit()`, at the default and largest text sizes
- [ ] Fix what the audit finds, including the countdown's spoken value
- [ ] Fix the truncated offer and ride titles
- [ ] Verify: the audits pass; simulator screenshots of every screen on iPhone 17e, iPhone 18 Pro Max, and iPhone Duo's outer display, at the default and largest text sizes, in light and dark mode; ask the user to check iPhone Duo's inner display and folding

## Before the PR

- [ ] Review with `swiftui-pro` (every view in `Features/`, `RootView`), against its accessibility, resizability, and navigation references
- [ ] Review with `swift-testing-pro` (`DriverModel` alert and offer tests)
- [ ] Review with `swift-concurrency-pro` only if a phase adds async work, such as the tap delay
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: status, decision log (including revisiting "Show an offer as the whole screen" and "Remove an expired offer without a message"), the open question for #9, and the README's test instructions if the UI test target changes them
