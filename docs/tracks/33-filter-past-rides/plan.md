# Plan for #33: Filter past rides

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load `swift-testing-pro` for `PastRideFilterTests`
- [x] Load `swiftui-pro`, with its accessibility, localization, and views references, for the filter menu, the empty state, the header, and the announcement in `PastRidesView`
- [x] `swift-concurrency-pro` doesn't apply: the filter is synchronous view state with no async work

## Phase 1: The filter's rule and text

- [x] Write failing tests: each filter matches the right rides and keeps their order; each filter's menu title; the empty state's title for Completed and Cancelled; the header text with singular and plural counts; the announcement for each filter with singular and plural counts
- [x] Add `PastRideFilter`, with the matching rule and its text
- [x] Verify: the tests pass, and matching only rides the driver cancelled for Cancelled, or getting a plural wrong, each makes a test fail

## Phase 2: The filter on Past Rides

- [x] No unit test: the chosen filter is state held in `PastRidesView`
- [x] Add the filter as `PastRidesView`'s own state, starting on Completed, and the toolbar menu, which shows a different symbol while a filter other than All Rides is on, the filtered list with its count header, the no-match empty state with a button to show all rides, and the announcement when the filter changes
- [x] Verify: the user runs the app and checks that Past Rides opens on Completed, that a choice survives viewing a ride's details and resets after leaving, each filter, the header, the empty state and its button, and the announcement with VoiceOver. No UI tests, per CLAUDE.md

## Before the PR

- [x] Review with `swift-testing-pro` (`PastRideFilterTests`)
- [x] Review with `swiftui-pro` (`PastRidesView`, `PastRideFilter`)
- [x] `swiftlint lint` reports no violations
- [x] Run `/code-review`, and fix or record each finding. Fixed: the announcement could be cut off as focus moved, now posted at high priority; the header's capitals; comments that said rides were hidden; "Showing all 0 rides"; the skills table's order. Recorded in the PR: the filter resetting after an offer interrupts Past Rides, the announcement filtering again, and All Rides' unused no-match text
- [x] Update docs/PLAN.md:
  - Status: #33 done, moved up to follow #12 and #13, with the reason in the decision log
  - Decision log: this track's decisions
  - The skills table: a row for #33
