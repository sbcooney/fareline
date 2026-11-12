# Plan for #46: Let the driver get help at pickup

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load `swift-testing-pro` for `RideCodingTests` and the mock data tests
- [x] Load `swiftui-pro`, with its accessibility reference, for `CurrentRideView` and `RideHelpSheet`
- [x] `swift-concurrency-pro` isn't loaded: no async code changes, and `Rider` stays `Sendable` with a `String?` property

## Phase 1: Riders have phone numbers

- [x] Write failing tests: a ride with a phone number round-trips through `Codable`, covered by the existing `everyStateRoundTrips` once the fixture has a number; a ride saved without one decodes with `nil` (in `RideCodingTests`); every mock rider has a different `202-555-01xx` number (a new `MockRideDataTests` in `FarelineTests/Services/`)
- [x] Add `Rider.phoneNumber: String?`, give each mock template a number, and add one to `TestFixtures.ride()`. Other callers, such as `WaitingListTests`, pass `nil`. `makeTemplate` gets an inline exception to SwiftLint's `function_parameter_count`
- [x] Verify: the tests pass. With the property added but no mock numbers, both mock data tests failed. Giving two mock riders the same number made the uniqueness test fail, and making `phoneNumber` non-optional made the old-history test fail with `keyNotFound`

## Phase 2: Get Help and the Help sheet

- [x] No unit test: the button's visibility is a status check in the view, and the actions are `Link`s (see the spec)
- [x] Add `RideHelpSheet` with Call Rider and Contact Fareline Support as `tel:` links, and Cancel Ride with its confirmation
- [x] Add Get Help under `RideStepButton` in `CurrentRideView`'s bottom inset, shown only at `driverArrived`, disabled like the Ride Options button
- [x] Add the new strings to `Localizable.xcstrings`, without staging the uncommitted changes already on `main`
- [x] Verify: the user checks the screens by eye, at their request, in place of screenshots and audits. A first run of a temporary UI test, deleted afterwards, confirmed Get Help is hidden en route and shown at pickup, then stopped when the light mode audit failed Get Help's contrast. The label now uses the primary color. That fix, the sheet, dark mode, the largest text size, and on trip weren't checked by a test. The user then ran the app and confirmed the screens and the calls alert look right

## Before the PR

- [x] Review with `swift-testing-pro` (`RideCodingTests`, `MockRideDataTests`, `TestFixtures`)
- [x] Review with `swiftui-pro` (`CurrentRideView`, `RideHelpSheet`)
- [x] Record both reviews, and why `swift-concurrency-pro` wasn't needed, in the PR's "Swift skill reviews" section
- [x] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [x] Update docs/PLAN.md: a #46 row in the status table, decision log entries for this track (including the revision of the 2026-11-03 decision about the bottom of the ride screen), and the README's feature list and "What I'd do with more time" (number masking)
