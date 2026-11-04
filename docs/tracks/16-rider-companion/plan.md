# Plan for #16: Rider Companion readiness

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Before starting

- [x] Load the Swift skills this issue needs: `swift-concurrency-pro` for `Fareline/Services/DriverService.swift` (renamed from `RideService.swift`), `MockRideService.swift`, and `DriverModel.swift`, where the protocol's `Sendable` conformance and documentation change. `swiftui-pro` and `swift-testing-pro` aren't needed, as no view or test changes.

## Phase 1: Rename the driver's service contract

- [x] No new test: a rename with no behavior change, which the compiler checks
- [x] Rename the protocol and its file, and update `MockRideService` and `DriverModel`
- [x] Update its documentation to say it's the driver's contract, and that a rider app would add its own beside it
- [x] Verify: all unit tests and UI tests pass, and `grep -w RideService` finds no use left in code

## Phase 2: Document the readiness

- [x] No unit test: documentation
- [x] Add the README's "Ready for a Rider Companion" section, from the spec
- [x] Update `docs/PLAN.md`'s Rider Companion considerations, Architecture diagram, Services, and project structure to the new name, and correct "a rider client could use the same contract"
- [x] Verify: every type and method the README names exists in the code

## Before the PR

- [x] The user reviews the README section and the rename once, with everything done
- [x] Review with `swift-concurrency-pro` (the renamed protocol, `MockRideService.swift`, `DriverModel.swift`), and record it in the PR's "Swift skill reviews" section
- [x] `swiftlint lint` reports no violations
- [x] Run `/code-review`, and fix or record each finding
- [x] Update docs/PLAN.md: #16's status, the decision log (the rename and the package timing), and the skills table
