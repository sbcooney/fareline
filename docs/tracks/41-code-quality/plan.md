# Plan for #41: Code quality pass before submission

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing, in its own commit. Check off tasks as they're done.

## Before starting

- [x] Load `swiftui-pro` (the views, `PrimaryActionButton`, the modifier, `RootView`), `swift-concurrency-pro` (`DriverModel`, `MockRideService`, `SubscriberList`), and `swift-testing-pro` (every new and moved test)

## Phase 1: Inject the clock

- [x] Write failing tests: exact end times through a manual time source
- [x] Add `timeSource` to `DriverModel`, and use it for completion and cancellation
- [x] Verify: tests pass, and fail with `.now` restored

## Phase 2: Rules on the model

- [x] Write failing tests: `canAnswerOffer`, `canClaimRide`, `canTakeRideStep`
- [x] Add them, and use them in the offer buttons, Waiting Riders, the step button, and Ride Options
- [x] Verify: tests pass, and a mutation check on each

## Phase 3: Shared button and tap guard

- [x] No unit test: view state
- [x] Add `PrimaryActionButton` and `ignoresTapsBriefly(after:)`, and use them in the three buttons
- [x] Verify: screenshots from a temporary test match the old ones, and UI tests pass. A temporary test also confirmed that an `accessibilityValue` applied outside `PrimaryActionButton` replaces its own, which Accept relies on

## Phase 4: Testable navigation

- [ ] Write failing tests: every `AppNavigation` case in the spec
- [ ] Add `AppNavigation`, and have `RootView` use it
- [ ] Verify: tests pass, mutation checks, and UI tests pass

## Phase 5: Queued steps as a pure function

- [x] Write failing tests: `DriverSession.applying(_:)`
- [x] Move the overlay out of `DriverModel`, done before phase 4 because phase 2 took the model past the file length limit
- [x] Verify: new and offline tests pass, and four mutation checks

## Phase 6: A smaller mock

- [ ] Write failing tests: `SubscriberList`, `WaitingList`
- [ ] Add them and the timer helper, and use them in `MockRideService`
- [ ] Verify: every mock test passes, and record whether the lint exceptions could go

## Phase 7: Folders

- [ ] No unit test: moves
- [ ] Move files, rename `RideServiceError+Message`, and update `docs/PLAN.md`'s project structure
- [ ] Verify: build and every test pass

## Phase 8: String Catalog

- [ ] Existing message tests cover the text
- [ ] Add `Localizable.xcstrings` with plural variations, and remove the hand-written cases
- [ ] Verify: message tests pass

## Phase 9: Comments

- [ ] No unit test: reading
- [ ] Remove comments that only restate the code
- [ ] Verify: build and lint pass

## Before the PR

- [ ] The user reviews in the app once, with everything done
- [ ] Review with `swiftui-pro`, `swift-concurrency-pro`, and `swift-testing-pro`, and record each in the PR
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: status, decision log, and project structure
