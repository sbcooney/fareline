# Plan for #34: Offer screen's largest-text audit fails with unattributed contrast issues

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing, apart from this audit until Phase 2. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [ ] Load `swiftui-pro`, with its accessibility and design references, for any change to `OfferView`'s bar
- [ ] `swift-testing-pro` doesn't apply: the audit is an XCTest UI test, and no unit tests change
- [ ] `swift-concurrency-pro` doesn't apply: no async code changes
- [ ] Check the simulator is settled, with a load under about 8, before every UI test run. Today's earlier failures came from an overloaded simulator

## Phase 1: Find the cause

- [ ] No unit test: the audit only runs in UI tests. A temporary UI test, not kept, records the frames of the rows and the bar at the largest text size, each audit issue's element and frame, and a screenshot
- [ ] Run the hypothesis checks from the spec: nothing behind the bar, then the countdown row if needed
- [ ] Stop within the agreed time, and bring the findings and a recommended fix to the user before changing anything

## Phase 2: Fix it

- [ ] Make the fix the user chooses: the screen, the test's exception, or both
- [ ] Verify: `testOfferScreenAtTheLargestTextSize` passes 5 times in a row on a settled simulator, and the full UI suite passes. Screenshots of the offer screen at the largest text size before and after, if the screen changes

## Before the PR

- [ ] Review with `swiftui-pro` (`OfferView`, if it changes)
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: #34's status, and a decision log entry that revises "Keep two exceptions in the offer screen's contrast audit"
