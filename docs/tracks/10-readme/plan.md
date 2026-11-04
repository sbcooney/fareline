# Plan for #10: README and visual reference

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load the Swift skills this issue needs: `swiftui-pro` for marking the Demo menu's and previews' text as not for translation, in `DemoMenu.swift`, `RideOptionsButton.swift`, and `RideOptionsSheet.swift`. The temporary screenshot test is XCTest, deleted before the PR, so `swift-testing-pro` doesn't apply.

## Phase 1: A String Catalog that building doesn't change

- [x] No new test: the message tests cover the plural entries
- [x] Mark the Demo menu's titles and the previews' placeholder text as not for translation, so no build adds or removes them
- [x] Commit the catalog as Xcode wrote it, leaving out the personal signing team
- [x] Verify: unit tests pass, and the catalog's keys match exactly the strings the build extracts

## Phase 2: Screenshots

- [x] No unit test: images
- [x] Capture the primary flow with a temporary UI test into `docs/images/`, then delete the test. Past Rides shows All Rides, so all three outcomes appear, and the status bar keeps the real time, so it agrees with the rides' times
- [x] Verify: each image shows what its alt text says, at a size that reads on GitHub

## Phase 3: The README

- [x] No unit test: documentation
- [x] Add the screenshots, "Trying the app", and the "Design" section, and extend future work, in the agreed order
- [x] Verify: every type, method, and file named was checked against the code, and each step in "Trying the app" against the code and demo data. The main flow and Past Rides were followed by the screenshot test on a fresh install. The user follows the rest during their review

## Before the PR

- [ ] The user reviews the README once, with everything done
- [x] `swiftlint lint` reports no violations, and all tests pass
- [ ] Run `/code-review`, and fix or record each finding
- [x] Update docs/PLAN.md: #10's status, the decision log (the visual reference, and correcting the String Catalog entry), and the deliverables checklist
