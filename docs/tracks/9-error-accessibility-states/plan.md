# Plan for #9: Error, empty, and accessibility states

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work. The phases follow the decisions in the spec.

## Before starting

- [x] Load `swiftui-pro`, with its accessibility, resizability, navigation, and views references
- [x] Load `swift-testing-pro` for the model tests
- [x] Measure today's problems first: screenshot every screen at the largest text size on iPhone 17e, iPhone 18 Pro Max, and iPhone Duo's outer display, so each later phase has a before and after

## Phase 1: One alert at a time

- [x] Write failing tests: a cancellation replaces an error; an error doesn't replace a cancellation; no redundant "no longer available" after a dismissed cancellation; a new offer clears an error but not a cancellation; dismissing clears the alert
- [x] Add `DriverAlert`, replace `lastError` and `cancelledRide` with `alert` on `DriverModel`, and present it with `alert(_:item:)` in `RootView`
- [x] Update the existing tests that check `lastError` or `cancelledRide`
- [x] Verify: the tests pass, and removing each precedence rule fails its test

## Phase 2: Failures and empty states

- [x] Write tests: every `RideServiceError` has a message; after each kind of failed action, the control is enabled and the state unchanged
- [x] Fix anything the tests find: nothing, as both passed straight away. They now guard against regressions
- [x] Verify: the tests pass. Past Rides with no rides is covered by `AccessibilityAuditTests`. Connecting and a missing past ride weren't checked. They can't be reached in the running app, as the mock connects at once and only real past rides are linked

## Phase 3: Offers without pulling the driver away

- [x] Write a failing test: the model reports an offer that ended without the driver responding, and not one they accepted or declined
- [x] Add that to `DriverModel`, as `unansweredOfferID`
- [x] No unit test for the views: add `PendingOfferBar` over pushed screens, opening the offer on tap, and remove the path clearing from `RootView`. A ride starting still clears the path
- [x] Announce an offer's arrival and end with VoiceOver, and add haptic feedback on arrival
- [x] Verify: `OfferUITests` checks that an offer on Past Rides shows the bar and leaves the driver there; tapping it opens the offer; it disappears when the offer ends; with Reduce Motion on, it fades

## Phase 4: Taps that can't land by accident

- [x] No unit test: the delay is view timing. Make Accept, Decline, and Go Offline ignore taps for 0.75 seconds after they appear, looking disabled and announced as unavailable until ready
- [x] Verify: screenshots taken 0.3 seconds apart show Accept, Decline, and Go Offline dimmed as they appear, then enabled. `OfferUITests` checks they work once ready. XCUITest can't check the delay itself, because it waits for animations that take longer than 0.75 seconds

## Phase 5: Labels, text sizes, and iPhone sizes

- [x] Add the `FarelineUITests` target, with launch arguments that open each screen, and a test per screen that calls `performAccessibilityAudit()`, at the default and largest text sizes
- [x] Fix what the audit finds, including the countdown's spoken value. The audit found only contrast issues, which go to #19's design system, so the audit leaves contrast out until then
- [x] Fix the truncated offer and ride titles, with the inline title style at accessibility sizes
- [x] Verify: the audits pass on iPhone 18 Pro at the default and largest text sizes. Screenshots at the largest text size of every screen on iPhone 17e, iPhone 18 Pro Max, and iPhone Duo's outer display before the changes, and of the home, offer, and ride screens in dark mode on iPhone 17e and iPhone Duo's outer display after. The user checks iPhone Duo's inner display and folding

## Before the PR

- [x] Review with `swiftui-pro` (every view in `Features/`, `RootView`), against its accessibility, resizability, and navigation references
- [x] Review with `swift-testing-pro` (`DriverModel` alert and offer tests)
- [x] Review with `swift-concurrency-pro` (the tap delay, `UITestLaunchOptions.prepare`, `respond(to:with:)`)
- [x] `swiftlint lint` reports no violations
- [x] Run `/code-review`, and fix or record each finding
- [x] Update docs/PLAN.md: status, decision log (including revisiting "Show an offer as the whole screen" and "Remove an expired offer without a message"), the open question for #9, and the README's test instructions if the UI test target changes them
