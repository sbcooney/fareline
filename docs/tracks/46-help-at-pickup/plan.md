# Plan for #46: Let the driver get help at pickup

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load `swift-testing-pro` for `RideCodingTests` and the mock data tests
- [ ] Load `swiftui-pro`, with its accessibility reference, for `CurrentRideView` and `RideHelpSheet`
- [x] `swift-concurrency-pro` isn't loaded: no async code changes, and `Rider` stays `Sendable` with a `String?` property

## Phase 1: Riders have phone numbers

- [x] Write failing tests: a ride with a phone number round-trips through `Codable`, covered by the existing `everyStateRoundTrips` once the fixture has a number; a ride saved without one decodes with `nil` (in `RideCodingTests`); every mock rider has a different `202-555-01xx` number (a new `MockRideDataTests` in `FarelineTests/Services/`)
- [x] Add `Rider.phoneNumber: String?`, give each mock template a number, and add one to `TestFixtures.ride()`. Other callers, such as `WaitingListTests`, pass `nil`. `makeTemplate` gets an inline exception to SwiftLint's `function_parameter_count`
- [x] Verify: the tests pass. With the property added but no mock numbers, both mock data tests failed. Giving two mock riders the same number made the uniqueness test fail, and making `phoneNumber` non-optional made the old-history test fail with `keyNotFound`

## Phase 2: Get Help and the Help sheet

- [ ] No unit test: the button's visibility is a status check in the view, and the actions are `Link`s (see the spec)
- [ ] Add `RideHelpSheet` with Call Rider and Contact Fareline Support as `tel:` links, and Cancel Ride with its confirmation
- [ ] Add Get Help under `RideStepButton` in `CurrentRideView`'s bottom inset, shown only at `driverArrived`, disabled like the Ride Options button
- [ ] Add the new strings to `Localizable.xcstrings`, without staging the uncommitted changes already on `main`
- [ ] Verify: the unit tests and existing UI audits pass. Screenshots, from a temporary UI test that isn't kept, show en route and on trip without Get Help, pickup with it, and the sheet, at the default and largest text sizes in light and dark. Accessibility Inspector reports no issues on the pickup screen and the sheet

## Before the PR

- [ ] Review with `swift-testing-pro` (`RideCodingTests`, `MockRideDataTests`, `TestFixtures`)
- [ ] Review with `swiftui-pro` (`CurrentRideView`, `RideHelpSheet`)
- [ ] Record both reviews, and why `swift-concurrency-pro` wasn't needed, in the PR's "Swift skill reviews" section
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: a #46 row in the status table, decision log entries for this track (including the revision of the 2026-11-03 decision about the bottom of the ride screen), and the README's feature list and "What I'd do with more time" (number masking)
