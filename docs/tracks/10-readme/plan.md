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

- [ ] No unit test: images
- [ ] Capture the primary flow with a temporary UI test into `docs/images/`, then delete the test
- [ ] Verify: each image shows what its alt text says, at a size that reads on GitHub

## Phase 3: The README

- [ ] No unit test: documentation
- [ ] Add the screenshots, "Trying the app", and the "Design" section, and extend future work, in the agreed order
- [ ] Verify: follow every step in "Trying the app" on a fresh simulator install, and check every type, method, and file named against the code

## Before the PR

- [ ] The user reviews the README once, with everything done
- [ ] `swiftlint lint` reports no violations, and all tests pass
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: #10's status, the decision log (the visual reference, and correcting the String Catalog entry), and the deliverables checklist
