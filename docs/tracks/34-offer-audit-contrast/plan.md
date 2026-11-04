# Plan for #34: Offer screen's largest-text audit fails with unattributed contrast issues

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing, apart from this audit until Phase 2. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load `swiftui-pro`, with its accessibility and design references, for any change to `OfferView`'s bar
- [x] `swift-testing-pro` doesn't apply: the audit is an XCTest UI test, and no unit tests change
- [x] `swift-concurrency-pro` doesn't apply: no async code changes
- [x] Check the simulator is settled, with a load under about 8, before every UI test run. Today's earlier failures came from an overloaded simulator

## Phase 1: Find the cause

- [x] No unit test: the audit only runs in UI tests. A temporary UI test, not kept, records the frames of the rows and the bar at the largest text size, each audit issue's element and frame, and a screenshot
- [x] Run the hypothesis checks from the spec: nothing behind the bar, then the countdown row if needed
- [x] Stop within the agreed time, and bring the findings and a recommended fix to the user before changing anything. Found in 3 minutes: at the largest text size, Pickup and Union Station are hidden behind the Accept and Decline bar but still on screen, and the audit measures their text against it. An opaque bar didn't stop it. The countdown row was never the cause, and the issue's "8" was the failure message counted 4 times, with 2 issues each

## Phase 2: Fix it

- [x] Make the fix the user chose: run contrast on its own in the largest-text test, and skip only text under the bar, through a new `ignoringContrastBelow:` option on `audit(_:)`. The countdown exception is removed
- [x] Verify: `testOfferScreenAtTheLargestTextSize` passes 5 times in a row on a settled simulator, and the full UI suite passes. The screen didn't change. Without the new exception, the test fails on exactly Pickup and Union Station

## Before the PR

- [x] Review with `swiftui-pro` (`OfferView`, if it changes): it didn't change, so the review doesn't apply
- [x] `swiftlint lint` reports no violations
- [x] Run `/code-review`, and fix or record each finding. Fixed: the bar's top now includes its padding. Recorded in the PR: `isHittable` can't tell covered text from visible text, partly hidden text stays checked, the default size keeps no exception, and the rest
- [x] Update docs/PLAN.md: #34's status, and a decision log entry that revises "Keep two exceptions in the offer screen's contrast audit"
