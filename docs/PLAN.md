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
| ✅ | #2 | Domain models and state machines | Foundation |
| ✅ | #3 | Mock ride service and driver store | Foundation |
| ⬜ | #4 | Change availability status | Required |
| ⬜ | #5 | View an incoming ride request | Required |
| ⬜ | #6 | Accept or decline a request | Required |
| ⬜ | #7 | View current ride information | Required |
| ⬜ | #8 | Review past rides | Required |
| ⬜ | #9 | Error, empty, and accessibility states | Quality |
| ⬜ | #19 | App icon | Quality |
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
SwiftUI views  →  DriverStore (@Observable, @MainActor)  →  RideService protocol  →  MockRideService
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

**Ride offers** connect the two. An offer is a proposal of one ride to one driver, with an expiry time. It moves from `pending` to `accepted`, `declined`, or `expired`. Declining or ignoring an offer ends the offer, not the ride, which stays `awaitingDriver`. This also lets the rider queue and self-assign reuse the same model.

Each type enforces only its own rules. The service coordinates changes across a ride, a driver, and an offer.

### State management

A single `@Observable`, `@MainActor` `DriverStore` is the app's source of truth. Views render its state and call its intent methods, such as `acceptPendingOffer()`. The store holds no business rules: it sends requests and replaces its state with the complete `DriverSession` the service returns. Sessions carry a version, so one that arrives late is ignored. Because every action goes through the store, offline support can later queue actions in one place.

### Services

`RideService` is the boundary a real backend would sit behind. `MockRideService` implements it as an actor with fixed data. It delivers session changes, including new offers, through an `AsyncStream`, and takes an injected `TimeSource` so tests don't wait on real delays. It can also simulate failures and events from elsewhere in the system, such as a rider cancelling.

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
- [ ] Every protocol conformance and annotation has a current use.
- [ ] `swiftlint lint` reports no violations.
- [ ] The PR description names the Swift skills that reviewed the changes and what changed as a result.
- [ ] `/code-review` has run on the PR, and its findings are fixed or have a recorded reason for being left.
- [ ] This plan is updated.

## Development flow

Each issue follows the same steps:

1. **While writing:** load the relevant Swift skills before starting, not just at the end.
2. **Before the PR:** review the changes against those skills' checklists, loading only the relevant reference files. Fix real problems and list unrelated modernization separately.
3. **On the PR:** run `/code-review` to check for correctness bugs. Run `/simplify` after larger changes, as a guard against over-engineering.
4. **Before merging:** a person reads and questions the code. Every part of it has to be explainable at the onsite.

| Issue | `swiftui-pro` | `swift-concurrency-pro` | `swift-testing-pro` |
|---|---|---|---|
| #2 Domain models | | Light (`Sendable`) | Main |
| #3 Mock service and store | Data flow only | Main | Main |
| #4–#8 Required features | Main | Where async work is involved | Yes |
| #9 Error and accessibility states | Main (accessibility, resizing, localization) | | |
| #11, #12, #14 Map and queues | Main | Live updates | Yes |
| #13 Self-assign | Main | Main (the conflict case) | Main |
| #15 Offline | Yes | Main (replay and ordering) | Main |

Skill findings are suggestions:

- If a skill suggests an API that Xcode 27.2 rejects, the toolchain wins.
- Skip a fix that adds complexity for little benefit, and record any significant skip in the decision log.

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
- Every pickup and drop-off has a recognizable name, such as "Union Station". Real addresses often don't, so with real data `Place.name` would need to become optional.
- A driver handles one ride at a time.
- A ride is offered to one driver at a time. It goes to another driver only after the current offer is declined or expires.
- The app runs in portrait only, not upside down or in landscape, even though drivers may mount phones sideways.
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
| 2026-11-02 | Support portrait only | Avoids layout and testing work on every screen. In exchange, the app doesn't suit a phone mounted sideways. |
| 2026-11-02 | Pass times into domain methods, rather than reading the clock | Keeps expiry and completion rules deterministic and easy to test, including exact boundaries. Callers must supply a time on each call. |
| 2026-11-02 | Treat a response at the exact expiry time as too late | Gives one clear boundary, so an offer can't be both accepted and expired. A tap at the last instant loses, which the UI must explain. |
| 2026-11-02 | Use typed throws for domain rules | Each rule has one known error type, so callers and tests can handle exact cases. It's less flexible if a method later needs to throw other errors, which is unlikely for pure rules. |
| 2026-11-02 | Leave `Codable` off domain types until #8 | Synthesized decoding would bypass the domain rules, and the storage choice isn't made yet. #8 adds whatever its choice needs, with validation if it uses `Codable`. |
| 2026-11-02 | Keep `default:` in transition switches | Each table stays short and readable, and an unlisted pair is safely rejected. In exchange, the compiler doesn't force a decision when a case is added, so a new valid transition has to be added deliberately. |
| 2026-11-02 | Offer a ride to one driver at a time | Drivers never lose a ride they've just accepted to another offer, and the flow is simpler. A ride can take longer to match than if several drivers were offered it at once, as each offer must end first. A driver can still claim a ride from the rider queue while it's offered to someone else, so accepting must check the current ride. |
| 2026-11-02 | Send complete, versioned session snapshots rather than individual changes | The app can't merge changes incorrectly or end up with an offer, ride, and driver that disagree, and ordering problems reduce to a version check. Snapshots would be wasteful with large data or a real network, where a backend might send changes instead. |
| 2026-11-02 | Name the store `DriverStore` rather than `AppStore` | Avoids confusion with Apple's App Store, and says what it holds. |
| 2026-11-02 | Use a small `TimeSource` protocol rather than the standard `Clock` | Domain rules work in `Date`s, and a custom `Clock` would need its own instant type. It's less standard, but simpler for one app. |
| 2026-11-02 | Let the mock decide when offers expire | A backend would own this rule, so the app only displays the countdown. A slow connection could show the expiry late, and the expiry rule still rejects a late response. |
| 2026-11-02 | Add conformances and annotations only when the code uses or requires them | Every line stays justifiable, and the code doesn't suggest uses that don't exist. Some, such as `Hashable` for navigation, may have to be added back later, and the compiler shows where. `Identifiable` is the exception: every type with an identity declares it, even before anything relies on it, because it describes what the type is. |
| 2026-11-02 | Accept and decline take an offer ID | A driver can't take a ride they never saw if the offer changes just before a tap. Views must pass the ID of the offer on screen. |
| 2026-11-02 | Treat declining an ended offer as success | The driver wanted to not take the ride, so an error would be misleading. The app can't tell the driver that the offer had already ended. |
| 2026-11-02 | Accept that a large system clock change can delay offer expiry in the mock | Expiry compares wall-clock dates, so moving the clock back delays expiry by that amount. Fixing this needs monotonic deadlines, which aren't worth it for a mock. A real backend would own expiry. |
| 2026-11-02 | Run tests in Debug only | `@testable import` needs testability, which is on only for Debug. Optimizer-only bugs wouldn't be caught, which is acceptable for this project's size. |

## Open questions

Decide these in the issue noted, then record the outcome in the decision log.

- **#8:** How should completed rides be stored? Start by comparing a `Codable` JSON file with SwiftData, keeping in mind what #15 will need.
- **#15:** Which actions can queue offline, and what happens when a queued action conflicts with the server state on reconnect?

## Deliverables checklist

- [ ] Public GitHub repository, with the link sent to the recruiting contact
- [ ] Clear build and run instructions
- [ ] Clean-clone check passed: the public repo clones and runs using only the README (see #17)
- [ ] One screenshot or a short recording of the primary flow
- [ ] README design section covering:
  - [ ] Architecture and state management
  - [ ] At least one real trade-off
  - [ ] What I'd change or add with more time
  - [ ] Simplifying assumptions
  - [ ] AI tools used and how
