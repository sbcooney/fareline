# Plan for #17: Final submission

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [ ] Load the Swift skills this issue needs: none of the three. The only code change is to the XCTest UI tests in `FarelineUITests/FarelineUITestCase.swift` and `FarelineUITests/AccessibilityAuditTests.swift`, which `swift-testing-pro` doesn't cover, and no app code changes

## Phase 1: Audits in both modes

- [ ] Write the failing check first: with #10's contrast fix reverted, the Past Rides audit must fail, whatever the simulator's appearance
- [ ] Set and restore the appearance in `FarelineUITestCase`, and loop each audit over light and dark
- [ ] Verify: every UI test passes, starting from the simulator in light and again in dark, the reverted fix fails, and the simulator ends in the appearance it started in

## Phase 2: Final documents

- [ ] No unit test: documentation
- [ ] Update the README's test section, and `docs/PLAN.md`'s status, decision log, and any section that no longer matches
- [ ] Verify: the README and plan read against the code, and no issue other than #17 is open

## Phase 3: Nothing private

- [ ] You revert your signing team, once you're done testing on your phone
- [ ] Search every commit for PDFs, keys, tokens, and absolute paths, and the project file for a signing team
- [ ] Verify: the searches find nothing

## Before the PR

- [ ] Fresh clone (Claude): clone the pushed branch into a new folder, with no DerivedData, and build and test with the README's terminal command
- [ ] `swiftlint lint` reports no violations, and all tests pass
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Open the PR, saying "Part of #17"

## After the PR merges

- [ ] You say to make the repository public, and Claude makes it public
- [ ] You open the public link in a private browser window, and check it's visible and the README renders
- [ ] Optionally, you open the fresh clone in Xcode and run it with no signing team selected
- [ ] You send the link to your recruiting contact
- [ ] Close #17
