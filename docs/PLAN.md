# Fareline: Project Plan

Fareline is a simplified rideshare app for drivers, built in Swift and SwiftUI for the Mark43 OnScene take-home assignment. All data is mocked. There is no authentication, payment processing, live backend, real GPS, or external API key.

**This is a living document.** Any change that completes an issue or alters a decision also updates this file. See [Keeping this plan current](#keeping-this-plan-current).

## Goals

- Deliver a clear, working driver flow with production-quality code.
- Favor depth over breadth. The assignment suggests a 2–3 hour time-box and values a focused, finished solution over a larger, half-finished one.
- Keep the code easy for a teammate to read, change, and discuss at the onsite.

## Status

Work proceeds top to bottom. Each row merges as its own PR and leaves the app working, so work can stop after any row and still produce a complete submission. Anything unfinished moves to "What I'd do with more time" in the README.

| Status | Issue | Work | Area |
|---|---|---|---|
| ✅ | #1 | Project setup | Setup |
| ⬜ | #2 | Domain models and state machines | Foundation |
| ⬜ | #3 | Mock ride service and app store | Foundation |
| ⬜ | #4 | Change availability status | Required |
| ⬜ | #5 | View an incoming ride request | Required |
| ⬜ | #6 | Accept or decline a request | Required |
| ⬜ | #7 | View current ride information | Required |
| ⬜ | #8 | Review past rides | Required |
| ⬜ | #9 | Error, empty, and accessibility states | Quality |
| ⬜ | #10 | README and visual reference | Deliverable |
| ⬜ | #12 | See a queue of waiting riders | Extended |
| ⬜ | #13 | Self-assign to a ride | Extended |
| ⬜ | #14 | See a queue of other drivers and their statuses | Extended |
| ⬜ | #11 | See other drivers on a map | Extended |
| ⬜ | #15 | Offline capability | Extended |
| ⬜ | #16 | Rider Companion readiness | Extended |
| ⬜ | #17 | Final submission | Deliverable |

Issue numbers follow the order they were filed, not the order of work. Status key: ⬜ not started, 🟨 in progress, ✅ done, ➖ not doing (with the reason in the decision log).

## Technical baseline

- **Platform:** iOS 27.2, built with Xcode 27.2 and Swift 6.4.
- **UI:** SwiftUI, avoiding UIKit.
- **Concurrency:** Swift Concurrency in Swift 6 language mode, with complete strict checking. Types aren't main-actor isolated by default. No `@unchecked Sendable` to silence diagnostics.
- **Tests:** Swift Testing for unit and integration tests.
- **Dependencies:** none beyond Apple frameworks. SwiftLint is a development tool only.

## Architecture

```
SwiftUI views  →  AppStore (@Observable, @MainActor)  →  RideService protocol  →  MockRideService
                          ↓
                  Domain state machines (pure, no UI or service dependencies)
```

### Domain

Two separate state machines hold the core rules. They are pure value types, so every valid and invalid transition can be tested without UI or timing.

**Ride lifecycle** describes the ride itself, and a rider app would read the same values:

```
awaitingDriver → driverEnRoute → driverArrived → inProgress → completed
```

A ride can also become `cancelled` before it starts.

**Driver availability** describes only the driver: `offline`, `available`, or `onRide`.

**Ride offers** connect the two. An offer is a proposal of one ride to one driver, with an expiry time. Declining or ignoring an offer ends the offer, not the ride, which stays `awaitingDriver`. This also lets the rider queue and self-assign reuse the same model.

### State management

A single `@Observable`, `@MainActor` store is the source of truth. Views render its state and call its intent methods, such as `accept(offer:)`. Because every action goes through the store, offline support can later queue actions in one place.

### Services

`RideService` is the boundary a real backend would sit behind. `MockRideService` implements it with fixed data, delivers offers through an `AsyncStream`, and takes an injected clock so tests don't wait on real delays. It can also simulate failures, which lets error handling be exercised and demonstrated.

### Project structure

Folders follow features, with one primary type per file. Each folder is created when its first file is added:

```
Fareline/
  App/         App entry point and dependency wiring
  Domain/      Rides, offers, drivers, state machines
  Services/    RideService protocol and mock implementation
  Persistence/ Local storage
  Features/    Availability, Offers, CurrentRide, RideHistory, ...
  Resources/   Asset catalog
FarelineTests/
```

The Xcode project uses folder-synced groups, so files added to these folders join their target automatically.

## Rider Companion considerations

The assignment says a Rider Companion app may be built later. No rider code is planned. Issue #16 audits the finished code and documents these choices in the README:

- Domain names describe the ride, not the driver's view of it. For example, `driverEnRoute` rather than `goingToPickup`.
- Ride state is separate from driver state, so a rider app needs only the ride lifecycle.
- `RideService` models what a backend would provide, so a rider client could use the same contract.
- Domain code stays free of driver UI dependencies, so it could move into a shared Swift package once a second app exists.

## Definition of done

Every issue must meet all of these before it closes:

- [ ] The app builds and runs, and all tests pass.
- [ ] New logic has Swift Testing coverage.
- [ ] Types, protocols, and non-obvious methods have `///` documentation.
- [ ] Inline comments explain why, not what.
- [ ] The relevant Swift skills have reviewed the changes: `swiftui-pro`, `swift-concurrency-pro`, `swift-testing-pro`.
- [ ] This plan is updated.

## Keeping this plan current

Each PR that closes an issue updates this file in the same PR:

1. Update the issue's row in [Status](#status).
2. Add any decision made or reversed to the [decision log](#decision-log), including what was given up.
3. Add any simplifying assumption to the [assumptions](#assumptions) and to the README.
4. Correct any section that no longer matches the code.

Past log entries aren't rewritten. A reversed decision gets a new entry that points back to the original.

## Assumptions

Each of these goes in the README's design section. Those marked *provisional* can change during implementation.

- There is one driver, with no sign-in.
- Locations, riders, and other drivers come from fixed mock data.
- A driver handles one ride at a time.
- *Provisional:* a driver can't go offline during an active ride.
- *Provisional:* an offer expires if ignored, and the driver stays available.

## Decision log

| Date | Decision | Reasoning and trade-off |
|---|---|---|
| 2026-11-02 | Name the app Fareline | It names a service rather than a driver tool, so it also works for a rider app. No exact conflict was found on GitHub, the App Store, or the web. This wasn't a formal trademark search. |
| 2026-11-02 | Target iOS 27.2 | Gives access to the newest APIs. In exchange, reviewers need Xcode 27.2 or later to build it, so the README states this up front and includes a visual reference. |
| 2026-11-02 | Keep one app target, with no shared package | A shared package now would be over-engineering for a rider app that may never exist. Keeping domain code independent keeps a later extraction cheap, though it will still take some work if the rider app happens. |
| 2026-11-02 | Separate ride state from driver state | Takes slightly more modeling than one combined state machine. It avoids mixing unrelated concerns and matches what a rider app would need. |
| 2026-11-02 | File every extended feature, built after the required ones | All are intended, but together they may exceed the time-box. Separate PRs and a fixed order mean stopping early still leaves a finished app. Offline goes last among the features because it touches the most code. |
| 2026-11-02 | Treat the Rider Companion as documentation and an audit | The assignment describes it as a possible future app, so building for it now would be speculative. |
| 2026-11-02 | Don't make types main-actor isolated by default | Domain types and the mock service shouldn't be tied to the main actor, so only UI-facing types are marked `@MainActor`. This takes more annotations than Xcode's newer default, but makes isolation explicit. |
| 2026-11-02 | Run SwiftLint separately, not as a build phase | Reviewers can build without installing SwiftLint, and script sandboxing stays on. In exchange, lint violations don't appear during builds, so linting has to be run deliberately. |
| 2026-11-02 | Support iPhone only | The assignment describes a driver's flow, and limiting devices keeps layout work focused. iPad would need its own layout pass. |

## Open questions

Decide these in the issue noted, then record the outcome in the decision log.

- **#8:** How should completed rides be stored? Start by comparing a `Codable` JSON file with SwiftData, keeping in mind what #15 will need.
- **#15:** Which actions can queue offline, and what happens when a queued action conflicts with the server state on reconnect?

## Deliverables checklist

- [ ] Public GitHub repository, with the link sent to the recruiting contact
- [ ] Clear build and run instructions
- [ ] One screenshot or a short recording of the primary flow
- [ ] README design section covering:
  - [ ] Architecture and state management
  - [ ] At least one real trade-off
  - [ ] What I'd change or add with more time
  - [ ] Simplifying assumptions
  - [ ] AI tools used and how
