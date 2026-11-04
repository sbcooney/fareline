# Plan for #17: Final submission

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load the Swift skills this issue needs: `swift-concurrency-pro` for the `@MainActor` teardown block in `FarelineUITests/FarelineUITestCase.swift`. This was missed when the plan was written, and found by `/code-review`, so the skill reviewed the code after it was written rather than before. `swift-testing-pro` doesn't cover XCTest UI tests, and no app code changes

## Phase 1: Audits in both modes

- [x] Write the failing check first: with #10's contrast fix reverted, the Past Rides audit must fail, whatever the simulator's appearance
- [x] Set and restore the appearance in `FarelineUITestCase`, and loop each audit over light and dark
- [x] Verify: every UI test passes, starting from the simulator in light and again in dark, the reverted fix fails in light mode with the simulator starting in dark, and the simulator ends in the appearance it started in

## Phase 2: Final documents

- [x] No unit test: documentation
- [x] Update the README's test section, and `docs/PLAN.md`'s status, decision log, and any section that no longer matches
- [x] Verify: the README and plan read against the code, and no issue other than #17 is open

## Phase 3: Nothing private

- [x] You revert your signing team, once you're done testing on your phone
- [x] Search every commit for PDFs, keys, tokens, and absolute paths, and the project file for a signing team. None in any commit. The signing team is only in the working copy
- [ ] Verify: the searches find nothing

## Before the PR

- [x] Fresh clone (Claude): clone the pushed branch into a new folder, with no DerivedData, and build and test with the README's terminal command. All 228 unit tests and 10 UI tests pass. A first run reported no UI tests, because another test was using the same simulator at the time
- [x] `swiftlint lint` reports no violations, and all tests pass
- [x] Run `/code-review`, and fix or record each finding
- [x] Review with `swift-concurrency-pro`: the teardown closure is `@MainActor`, as `XCUIDevice` requires, and captures only the original appearance, a `Sendable` enum. No findings
- [ ] Open the PR, saying "Part of #17"

## After the PR merges

- [ ] You say to make the repository public, and Claude makes it public
- [ ] You open the public link in a private browser window, and check it's visible and the README renders
- [ ] Optionally, you open the fresh clone in Xcode and run it with no signing team selected
- [ ] You send the link to your recruiting contact
- [ ] Close #17
