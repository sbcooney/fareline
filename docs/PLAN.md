# Fareline: Project Plan

Fareline is a simplified rideshare app for drivers, built in Swift and SwiftUI as a demo project for a take-home assignment. All data is mocked. There is no authentication, payment processing, live backend, real GPS, or external API key.

**This is a living document.** Any change that completes an issue or alters a decision also updates this file. See [Keeping this plan current](#keeping-this-plan-current).

## Goals

- Deliver a clear, working driver flow with production-quality code.
- Favor depth over breadth. The assignment suggests a 2–3 hour time-box and values a focused, finished solution over a larger, half-finished one.
- Keep the code easy for a teammate to read, change, and discuss at the onsite.

## Status

Work proceeds top to bottom. Each row merges as its own PR and leaves the app working, so work can stop after any row and still produce a complete submission. Anything unfinished moves to "What I'd do with more time" in the README. The exception is #5 through #7, which belong together: until #7, a driver who accepts a ride can't finish it.

| Status | Issue | Work | Area |
|---|---|---|---|
| ✅ | #1 | Project setup | Setup |
| ✅ | #2 | Domain models and state machines | Foundation |
| ✅ | #3 | Mock ride service and driver store | Foundation |
| ✅ | #4 | Change availability status | Required |
| ✅ | #5 | View an incoming ride request | Required |
| ✅ | #6 | Accept or decline a request | Required |
| ✅ | #7 | View current ride information | Required |
| ✅ | #26 | Per-issue spec and plan in the development flow | Setup |
| ✅ | #8 | Review past rides | Required |
| ✅ | #9 | Error, empty, and accessibility states | Quality |
| ✅ | #19 | App icon, launch screen, and design system | Quality |
| ✅ | #31 | Let the driver cancel their current ride | Extended |
| ✅ | #12 | See a queue of waiting riders | Extended |
| ✅ | #13 | Self-assign to a ride | Extended |
| ✅ | #33 | Filter past rides | Extended |
| ➖ | #14 | See a queue of other drivers and their statuses: described in #10 instead | Extended |
| ➖ | #11 | See other drivers on a map: described in #10 instead | Extended |
| ➖ | #23 | Status outside the app: described in #10 instead | Extended |
| ✅ | #15 | Offline capability | Extended |
| ✅ | #16 | Rider Companion readiness | Extended |
| ✅ | #34 | Offer screen's largest-text audit fails with unattributed contrast issues | Quality |
| ✅ | #41 | Code quality pass before submission | Quality |
| ✅ | #10 | README and visual reference | Deliverable |
| 🟨 | #17 | Final submission: the audits in both modes and the final checks are done, and making the repository public and sending the link follow | Deliverable |

Issue numbers follow the order they were filed, not the order of work. Status key: ⬜ not started, 🟨 in progress, ✅ done, ➖ not doing (with the reason in the decision log).

## Technical baseline

- **Platform:** iOS 27.2, built with Xcode 27.2 and Swift 6.4.
- **UI:** SwiftUI, avoiding UIKit.
- **Concurrency:** Swift Concurrency in Swift 6 language mode, with complete strict checking. Types aren't main-actor isolated by default. No `@unchecked Sendable` to silence diagnostics.
- **Tests:** Swift Testing for unit and integration tests.
- **Dependencies:** none beyond Apple frameworks. SwiftLint is a development tool only.

## Architecture

```
SwiftUI views  →  DriverModel (@Observable, @MainActor)  →  DriverService protocol  →  MockRideService
                                                                                    ↓
                                                              Domain state machines (pure, no UI or service dependencies)
```

### Domain

Two separate state machines hold the core rules. They are pure value types, so every valid and invalid transition can be tested without UI or timing.

**Ride lifecycle** describes the ride itself, and a rider app would read the same values:

```
awaitingDriver → driverEnRoute → driverArrived → inProgress → completed
```

A ride can also become `cancelled`, and records who cancelled it. A rider can cancel until the trip starts. A driver can cancel a ride they're on at any stage, including during the trip.

**Driver availability** describes only the driver: `offline`, `available`, or `onRide`.

**Ride offers** connect the two. An offer is a proposal of one ride to one driver, with an expiry time. It moves from `pending` to `accepted`, `declined`, or `expired`. Declining or ignoring an offer ends the offer, not the ride, which stays `awaitingDriver`.

**The waiting list** holds rides that no driver took. Every new request is offered first. A ride joins the list once its offer is declined, expires, or ends because the driver went offline, or when the driver who accepted it cancels before the trip, which gives the rider a new request with their original request time. A ride being offered is never in the list, and a ride in the list isn't offered again. The driver can claim a ride from the list, which starts it as accepting an offer does and declines any pending offer. Being passed over is about dispatch, not the ride's lifecycle, so the service tracks it, and the ride's status stays `awaitingDriver`.

Each type enforces only its own rules. The service coordinates changes across a ride, a driver, and an offer.

### State management

A single `@Observable`, `@MainActor` `DriverModel` is the app's source of truth. Views render its state, ask it what the driver can do now, such as `canAnswerOffer`, and call its intent methods, such as `acceptOffer(id:)`. Navigation is view state, so it stays in `RootView`, but its rules are in `AppNavigation`, a value type with its own tests. The model holds no business rules: it sends requests and replaces its state with the complete `DriverSession` the service returns. Sessions carry a version, so one that arrives late is ignored.

The one exception is offline. The service reports the connection through `connectionUpdates()`, which a real client would feed from `NWPathMonitor`, so nothing polls. While it's down, the driver's own ride steps queue in the model's `pendingSteps`, and the session on screen is the service's last session with those steps applied by the domain's own transition rules, through `DriverSession.applying(_:)`. On reconnecting, the steps are sent in order, and the service's answer wins any conflict.

### Services

`DriverService` is the driver's boundary with the backend, and a rider app would add its own beside it. `MockRideService` implements it as an actor with fixed data. It delivers session changes, including new offers, through an `AsyncStream`, and takes an injected `TimeSource` so tests don't wait on real delays. It can also simulate failures and events from elsewhere in the system, such as a rider cancelling. In the demo, riders whose names describe what they do trigger these events, so a reviewer knows what to expect. Will Cancel cancels 10 seconds after the driver accepts, unless the trip has already started. Taylor Taken, in the waiting list, is taken by another driver just as this driver claims their ride.

### Project structure

Folders follow features, with one primary type per file. Each folder is created when its first file is added:

```
Fareline/
  App/         Entry point, dependency wiring, root view, and navigation
  Model/       DriverModel, the app's state and intents, and what it shows offline
  Domain/      Rides, offers, drivers, state machines
  Services/    DriverService protocol and mock implementation
  Features/    Availability, Offers, CurrentRide, PastRides, WaitingRiders, Connection, Shared
  Debug/       The Demo menu and UI test launch options, in Debug builds only
  Resources/   Asset catalog, including the design system's color tokens
FarelineTests/ The same folders, plus TestSupport/ for fixtures and the manual time source
```

The Xcode project uses folder-synced groups, so files added to these folders join their target automatically.

## Rider Companion considerations

The assignment says a Rider Companion app may be built later. No rider code is built. #16 audited the finished code, and the README's "Ready for a Rider Companion" section documents the result:

- Domain names describe the ride, not the driver's view of it. For example, `driverEnRoute` rather than `goingToPickup`.
- Ride state is separate from driver state, so a rider app needs only the ride lifecycle, whose rules already cover the rider's cancellation.
- `DriverService` is the driver's contract, returning a `DriverSession`. A rider app would add a `RiderService` and `RiderSession` beside it, keeping the same conventions, served from the same backend state as `MockRideService`.
- Domain code imports only Foundation, so it could move into a shared Swift package once a second app exists.
- A rider app would still need what the driver app doesn't: the driver's name and vehicle, a history that includes rides cancelled before a driver was assigned, and its own display wording.

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

1. **Before any code:** run `/start-issue <number>`, which writes `docs/tracks/<number>-<slug>/spec.md` and `plan.md` from the issue. The spec lists the expected behavior and the cases the tests must cover. The plan breaks the work into phases, each with failing tests first and a verify step. A person reviews both and decides any open questions before work starts. Tracks begin with #8.
2. **While writing:** load the relevant Swift skills before starting, not just at the end.
3. **Before the PR:** review the changes against those skills' checklists, loading only the relevant reference files. Fix real problems and list unrelated modernization separately.
4. **On the PR:** run `/code-review` to check for correctness bugs. Run `/simplify` after larger changes, as a guard against over-engineering.
5. **Before merging:** a person reads and questions the code. Every part of it has to be explainable at the onsite.
6. **After a repeated mistake:** a mistake an agent makes twice becomes a rule in `CLAUDE.md`, with the reason.

| Issue | `swiftui-pro` | `swift-concurrency-pro` | `swift-testing-pro` |
|---|---|---|---|
| #2 Domain models | | Light (`Sendable`) | Main |
| #3 Mock service and store | Data flow only | Main | Main |
| #4–#8 Required features | Main | Where async work is involved | Yes |
| #9 Error and accessibility states | Main (accessibility, resizing, localization) | | |
| #12 Rider queue | Main | Live updates | Yes |
| #13 Self-assign | Main | Main (the conflict case) | Main |
| #33 Past rides filter | Main | | Yes |
| #15 Offline | Yes | Main (replay and ordering) | Main |
| #16 Rider Companion | | Light (the renamed protocol) | |
| #17 Final submission | | | Not used: only XCTest UI tests change |
| #41 Code quality pass | Main (shared views, navigation) | Main (the mock's timers and subscribers) | Main |

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
- Other drivers are simulated. They pass on new requests, which joins them to the waiting list, and one demo rider's ride is taken by another driver just as this driver claims it. In the demo, other drivers stop passing on requests once six riders are waiting. Declines, expiries, and the driver's own cancellations still add to the list, and waiting riders never give up.
- The app runs in portrait only, not upside down or in landscape, even though drivers may mount phones sideways.
- *Provisional:* a driver can't go offline during an active ride.
- An offer expires if ignored, and the driver stays available.
- A rider can cancel until the trip starts, and the driver is told why their ride ended.
- A driver can cancel at any stage, after a confirmation, and earns no fare for a cancelled ride. The mock has no distance travelled, so there's no partial fare for a trip ended early.
- Being offline is simulated with a Debug-only Demo menu, as the app has no real network. A real client would learn about its connection from `NWPathMonitor`.
- Queued ride steps don't survive relaunching the app while offline. The mock "server" restarts with the app and saves only past rides, so surviving a relaunch would need the app and the mock to save their whole state.
- When the service refuses a queued step, the service wins: the steps after it are dropped, rather than each kind of conflict being resolved differently.
- Past rides are kept on the device, as the mock's stand-in for a backend's history, and aren't synced anywhere.

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
| 2026-11-02 | Don't adopt OpenSpec | Showing its worth would mean using it for every task with a custom workflow, and building that would take time from the app. In exchange, expected behavior stays in issues, tests, and PR descriptions rather than in one living spec. |
| 2026-11-02 | Use a button rather than a `Toggle` to change availability | The change waits on the service, while a toggle suggests it has already happened. A button can show progress and only reports the new status once it's confirmed. |
| 2026-11-02 | Show an offer as the whole screen rather than a sheet | A driver has one thing to decide, and a sheet could be swiped away and leave the offer running unseen. In exchange, the driver can't reach other screens until they respond or the offer expires. |
| 2026-11-02 | Remove an expired offer without a message | The driver sees the available screen again, which keeps the flow simple. In exchange, nothing says why the offer disappeared. |
| 2026-11-02 | Add a root `NavigationStack` and an `AppDestination` enum before any screen is pushed | Adding a screen means adding one case, and the compiler requires its view. This is a deliberate exception to adding code only when it's used, as navigation is structure the app will need. Its one case, `pastRides`, has a placeholder view and no link until #8, because Swift doesn't allow a `switch` with no cases. |
| 2026-11-02 | Run tests in Debug only | `@testable import` needs testability, which is on only for Debug. Optimizer-only bugs wouldn't be caught, which is acceptable for this project's size. |
| 2026-11-03 | Write a spec and plan for each issue, without OpenSpec tooling (revisits "Don't adopt OpenSpec") | Agreeing on behavior and test cases before code catches misunderstandings while they're cheap, and gives a reviewer the intent behind each PR. A `/start-issue` skill and two Markdown files need no setup. In exchange, specs describe one issue and aren't kept current afterwards, unlike OpenSpec's living specs. |
| 2026-11-03 | Keep cancelled rides in the session's `pastRides`, replacing `completedRides` | Each ride's status already says how it ended, so the session explains a cancellation without a new type. In exchange, the store has to compare sessions to notice that its active ride was cancelled, and #8 has to decide whether history shows cancelled rides. |
| 2026-11-03 | Tell the driver about a rider cancellation with an alert | The ride screen disappears without warning otherwise, and an alert makes sure the driver sees why. In exchange, it interrupts the driver, which a quieter banner wouldn't. |
| 2026-11-03 | Trigger demo events with descriptively named mock riders, such as Will Cancel | A reviewer can see a cancellation without a debug menu, and the name says what will happen. Behavior is fixed per rider, so other events need their own riders. |
| 2026-11-03 | Ride steps take a ride ID, like accepting an offer | A tap always applies to the ride on screen, and the store no longer silently ignores a step with no active ride. Views must pass the ride's ID. |
| 2026-11-03 | Show only the cancellation when a step fails because the rider cancelled | Two alerts would compete, and "no longer available" says less than the cancellation does. The store hides that one error while a cancellation is waiting to be seen. |
| 2026-11-03 | Rename `DriverStore` to `DriverModel` (revisits "Name the store `DriverStore` rather than `AppStore`") | #8 adds `PastRideStore`, which saves rides to a file, and "Store" shouldn't mean two things. `DriverModel` follows Apple's naming for `@Observable` app models. In exchange, the name says less about the pattern: views still act through it, not just read it. |
| 2026-11-03 | Save past rides in `MockRideService`, through `PastRideStore` | The mock plays the backend, which would own history, and the session already delivers `pastRides`, so the app stays a renderer. In exchange, the app has no cache of its own yet. #15 adds one for offline use. |
| 2026-11-03 | Save past rides as a `Codable` JSON file rather than with SwiftData | Domain types are value types whose rules are enforced through `apply(_:)`, and SwiftData would need separate `@Model` classes mirroring them. Decoding replays the ride's events so invalid saved state is rejected, and an unreadable file is moved aside rather than overwritten. In exchange, the whole file is rewritten on each save, and loaded on the main thread at launch, which is fine for one driver's history. |
| 2026-11-03 | Show cancelled rides in past rides | The driver drove toward the pickup and may want to see it. Each is labeled "Cancelled" with no fare, so it isn't mistaken for earnings. |
| 2026-11-03 | Replace `completedAt` with `endedAt`, and give `.cancelled` a date | Cancelled rides can be sorted and show when they ended, and the status already says how. This changes a domain event, so every caller of `.cancelled` passes a time. |
| 2026-11-03 | Clear the navigation path when an offer arrives or a ride starts | A driver on a pushed screen can't miss an offer or a ride, including one self-assigned from a pushed screen in #13. In exchange, they lose their place in Past Rides. #9 may revisit how offers appear. |
| 2026-11-03 | Name the folder `Features/PastRides/`, not `RideHistory/` | It matches the screen's title and `AppDestination.pastRides`. |
| 2026-11-03 | Turn off SwiftLint's `file_length` rule for `MockRideService.swift` | The actor's state is private, and splitting the file would mean exposing it to the whole module. In exchange, the file can grow past the limit unnoticed, so it should be split if it gains another responsibility. |
| 2026-11-03 | Show an offer over pushed screens as a bar at the bottom, and keep it as the home screen's content (revisits "Show an offer as the whole screen rather than a sheet" and "Clear the navigation path when an offer arrives or a ride starts") | A driver browsing Past Rides keeps their place, and an offer is still never missed. On the home screen, an available driver is waiting for offers, so taking over loses nothing. In exchange, an offer looks different depending on where the driver is. A ride starting still clears the path. |
| 2026-11-03 | Ignore taps on Accept, Decline, and Go Offline for 0.75 seconds after they appear | Accept appears where Go Offline was, and the reverse, so a tap meant for one could trigger the other. A confirmation step would slow every response. In exchange, a driver who's quick and sure waits a moment. |
| 2026-11-03 | Announce an ended offer with VoiceOver only | A VoiceOver user can't see the offer screen go away. Sighted drivers can, so "Remove an expired offer without a message" otherwise stands. |
| 2026-11-03 | Show one alert at a time through a `DriverAlert` enum | One property decides which explanation the driver sees, replacing special cases spread across two. In exchange, every test that checked `lastError` changes. |
| 2026-11-03 | Don't add a retry button to the error alert | The control that failed stays enabled, and a retry button would mean remembering the last action. |
| 2026-11-03 | Add a UI test target that runs Apple's accessibility audit on each screen | It catches missing labels, clipped text, and contrast problems that screenshots miss. In exchange, the project gains an XCTest target, since Swift Testing doesn't support UI tests, and launch arguments that open each screen. |
| 2026-11-03 | Use the inline title style at accessibility text sizes on the offer and ride screens | Large titles truncate, and no way to wrap them was found. The inline title fits in full on the smallest iPhone, so the wording doesn't have to change. |
| 2026-11-03 | Leave contrast out of the accessibility audits until #19 | The audits found only contrast issues, from the system's default blue and secondary gray. #19's design system chooses brand colors with contrast-checked tokens, so the colors are fixed once, after the icon concept. Until then, the app falls just short of WCAG AA contrast. |
| 2026-11-03 | Keep color tokens as named colors in the asset catalog | Each color is defined once with light and dark values, Xcode generates Swift names for them, and the launch screen can use the same names. In exchange, values are edited in Xcode's color editor or JSON rather than in Swift. |
| 2026-11-03 | Name color tokens by role prefix: `brand…`, `text…`, `surface…`, `status…` | Related colors group together, and the brand tint is `brandPrimary` rather than Xcode's default `AccentColor`, so every token follows one scheme. The accent color build setting points at `brandPrimary`. |
| 2026-11-03 | Use a deep blue as the brand color | It stays close to iOS's own blue, so the app feels native, and is dark enough for white text on it to pass contrast. Green was avoided because it already means "available". |
| 2026-11-03 | Draw the icon and launch mark with a Swift script | The artwork is reproducible and reviewable as code, and follows the brand tokens. In exchange, it can't use Icon Composer's layered Liquid Glass effects. |
| 2026-11-03 | Add `textOnBrand`, near-black in dark mode, for text on filled buttons | In dark mode, no single blue passes contrast both as text on dark gray and behind white text. A lighter blue with dark text passes both. In exchange, dark mode's filled buttons look different from the system's usual white-on-blue. |
| 2026-11-03 | Keep two exceptions in the offer screen's contrast audit | The audit reports Decline's text on its glass capsule as failing, though it measures 6.3:1, and intermittently reports a failure with no element that only removing the countdown row fixes. Each exception covers exactly that issue and is explained in the test, so any other contrast problem on the screen still fails. |
| 2026-11-03 | Draw the countdown from a once-a-second redraw rather than a self-updating timer | The visible time and VoiceOver's spoken value come from the same clock, so they can't disagree. In exchange, the row redraws every second while an offer is showing. |
| 2026-11-03 | Do #31 next, then the extended features, and move #10 to just before #17 | #31 fills a gap in the ride flow, and changes the current ride screen the README's screenshots show. Writing the README once, after the features, avoids redoing it. In exchange, the repository has no finished README until near the end. |
| 2026-11-03 | Record who cancelled a ride with `RideEvent.cancelled(by: RideRole, date:)` | The driver's history, the model's alerts, and a future rider app all need to tell a driver's cancellation from a rider's. `RideRole` names a party to the ride rather than one participant's view. Every caller of `.cancelled` passes who cancelled. |
| 2026-11-03 | Let only the driver cancel during a trip, with no fare | A driver may need to stop when a trip becomes unsafe, while a rider in the car shouldn't cancel it. A partial fare needs distance the mock doesn't have, and Complete Trip already ends a trip with the full fare. In exchange, the lifecycle's rule now depends on who cancels. |
| 2026-11-03 | Confirm before cancelling, with a message for each stage | A cancellation can't be undone and costs the driver the fare, so it shouldn't happen from one tap. The confirmation is an alert, so both choices are always visible in the middle of the screen. A confirmation dialog would appear as a popover without its Keep Ride button. |
| 2026-11-03 | Put Cancel Ride in a Ride Options sheet, opened from the top of the ride screen | A button below the step button was easy to tap by mistake and made a rare action prominent. A menu drew a floating pill over the title, which looked odd even for one choice. A sheet sized to its content keeps the bottom for the next step, and "Ride Options" leaves room for other ride actions, where "Help" would promise help content the app doesn't have. In exchange, cancelling takes one more tap. |
| 2026-11-03 | Show the cancellation flow with screenshots rather than UI tests | Unit tests cover the model and service. UI tests of the first confirmation needed a coordinate tap to dismiss a popover and audit exceptions for the system's dialog, and were slow, for wiring the screenshots already show. |
| 2026-11-03 | Read a cancelled ride saved without `cancelledBy` as cancelled by the rider | Every cancellation before #31 was a rider's, so existing history stays readable rather than being moved aside as damaged. |
| 2026-11-03 | Turn off SwiftLint's `type_body_length` rule for `MockRideService.swift` (extends the `file_length` entry above) | `cancelRide(rideID:)` took the actor's body past 200 lines, for the same reason: its private state can't move to another file. |
| 2026-11-03 | Do #12 and #13 together, in one PR | #13 was split from #12 only to keep PRs small, and a queue the driver can't act on isn't useful on its own. In exchange, the PR is larger. |
| 2026-11-03 | Describe a map of other drivers (#11), a list of other drivers (#14), and status outside the app (#23) in the README's future work, rather than building them | The mock has no real locations, other drivers would be invented and never change, and status outside the app needs push updates the mock can't send. #10 describes each, with why it matters and why it wasn't built. In exchange, the app has none of them. |
| 2026-11-03 | Offer every new request first, and list only rides that no driver took | This is closer to how dispatch works, gives the list a clear purpose, and leaves less room to pick only the best fares. In exchange, a ride can't appear in the list while it's being offered, and the demo needs simulated drivers who pass on requests, or the list would hold only rides this driver declined. |
| 2026-11-03 | Give the rider a new request in the list when the driver cancels before the trip, with the original request time | The rider still needs a ride, and the driver's history still shows the cancellation. A ride cancelled during the trip is over, as the rider was already in the car. In exchange, the rider's new request has a new ID. |
| 2026-11-03 | Carry the list as `DriverSession.waitingRides`, and track passed-over rides in the service | One snapshot shows a claimed ride leave the list and become active together. Being passed over is about dispatch, so the ride's status stays `awaitingDriver`. In exchange, the session grows with the list. |
| 2026-11-03 | Show the list on a pushed Waiting Riders screen, opened from the home screen's toolbar, and keep it visible while offline | The home screen stays focused on availability, and an offline driver can decide whether going online is worth it. Take Ride is disabled while offline. |
| 2026-11-03 | Decline a pending offer when the driver claims a ride from the list | The driver has chosen, and the offer's ride joins the list for someone else. In exchange, a driver can't hold an offer while claiming another ride. |
| 2026-11-03 | Keep a claim's conflict message when a new offer arrives (an exception to clearing errors when an offer arrives) | The message says the rider is no longer waiting, so it can't be mistaken for one about the offer, and without it a failed claim looked like a tap that did nothing. Other errors are still cleared. |
| 2026-11-03 | Return to the screens the driver left after an offer opened from the bar ends without a ride, and to Waiting Riders after cancelling a ride taken from it before the trip (revises "Clear the navigation path when an offer arrives or a ride starts") | A driver browsing the list stays where they were. A completed ride, a ride cancelled on trip, and a rider's cancellation still end on the home screen. In exchange, `RootView` keeps navigation state that has no unit test. |
| 2026-11-03 | Never make a new request for a rider who already has one waiting or in progress, and give the seeded list its own riders | A driver could otherwise see the same person asking for two rides, in the list and in an offer. In exchange, if every repeating rider is waiting, no offer is made until one leaves the list. |
| 2026-11-03 | Seed the demo's waiting list through a `waitingRides` parameter on `MockRideService` | Tests and UI tests build services that start empty, and only the app passes `MockRideData.passedOverRides(at:)`. |
| 2026-11-03 | Build the past rides filter (#33) next, rather than leave it as future work | A driver's history now holds rides cancelled by either party, so finding the rides they were paid for gets harder as it grows. In exchange, #15 and #16 move later. |
| 2026-11-03 | Open Past Rides on Completed, with one Cancelled choice for both parties | The rides a driver was paid for come first, and each cancelled row already says who cancelled. A count header, such as "3 of 8 rides", shows that some rides are hidden. |
| 2026-11-03 | Keep the past rides filter in the screen's own state, resetting to Completed each time Past Rides opens | The screen always opens the same way, and a choice survives viewing a ride's details. Remembering it until the app closes would depend on a restart the driver can't see. In exchange, a driver who prefers All Rides chooses it each visit. |
| 2026-11-03 | Write singular and plural text in code, in `PastRideFilter` | The project has no String Catalog yet, so the text is English only. A catalog's plural variations would replace these cases. |
| 2026-11-03 | Skip only text hidden under the Accept and Decline bar in the largest-text offer audit, replacing the countdown row's exception (revises "Keep two exceptions in the offer screen's contrast audit") | At the largest text size, the last rows scroll under the bar, hidden but still on screen, and the audit measures their text against it. Removing the countdown row only helped by moving rows up. Contrast runs on its own in that test, so each issue names its element, and any other contrast issue still fails. Decline's exception stays. In exchange, the test depends on the bar's position, read from the Decline button. |
| 2026-11-03 | Keep #15 to what makes the app useful offline, and document the rest as assumptions | The assignment asks only for "offline capability in case of loss of connectivity", and warns against over-engineering. Surviving a relaunch offline, real network monitoring, and conflict handling per case are assumptions in the README rather than code. |
| 2026-11-03 | Queue the driver's own ride steps offline, including Cancel Ride, and disable everything else | Steps on a ride the driver is already on don't need anyone else's answer, and a driver may need to end an unsafe trip without signal. Accepting, declining, taking a ride from the list, and changing availability need a live answer. |
| 2026-11-03 | Show queued steps straight away, by applying them to the service's last session with the domain's rules | The driver can keep going, and the screen can't jump back when the service's older session arrives on reconnecting. In exchange, the model holds a little logic of its own, and it compares news against the service's session, not the one on screen. |
| 2026-11-03 | Let `completeTrip` and `cancelRide` take the time of the tap | A trip completed offline keeps its real end time, as a backend would accept a client's timestamp. In exchange, the protocol changed, and the service trusts the client's time. |
| 2026-11-03 | Let the service win a conflict when replaying | Steps after a refused one would build on a ride that no longer exists as the driver saw it, so they're dropped, and the driver is told. A rider's cancellation shows its own alert instead. |
| 2026-11-03 | Report the connection through a stream from the service, and simulate it with a Debug-only Demo menu | Nothing polls. A real client would feed the same stream from `NWPathMonitor`. The menu is on every main screen, so the connection can be lost mid-ride. |
| 2026-11-03 | Show a lost connection with a brief toast, and a status button in the navigation bar while it lasts, saying "no connection" | Losing the connection is usually brief, so a toast over the content tells the driver without moving the screen. A button stays in the bar for a longer loss, so an available driver knows why no offers arrive. A banner was tried first: it moved the screen, and the ride and offer screens had to switch to small titles. "Offline" already means a driver who isn't taking rides. |
| 2026-11-04 | Rename `RideService` to `DriverService` | Every method is a driver action and it returns a `DriverSession`, so the old name suggested a contract a rider app could share, which it couldn't. The new name pairs with `DriverSession` and `DriverModel`, and leaves room for a `RiderService`. `MockRideService` and `RideServiceError` keep their names, as the mock plays the whole backend and the errors come from the ride backend, with some cases, such as `networkUnavailable`, applying to either client. |
| 2026-11-04 | Describe a shared Swift package in the README rather than create one | One app gains nothing from a package, which would need `public` on every shared type and its own test target. The README says when to move: once a second app target exists. In exchange, a rider app would start with that move. |
| 2026-11-04 | Do a code quality pass (#41) before the README | A review of the whole project as a Swift expert would see it found no bugs, but copied view code, rules in views, untested navigation, a clock read directly, and folders that mixed concerns. Fixing them first means the README describes the final code. In exchange, #10 starts later. |
| 2026-11-04 | Give `DriverModel` an injected `TimeSource` for ride end times | Completion and cancellation read the clock directly, unlike the rest of the project, so a test could only check a range. Now it checks the exact time. |
| 2026-11-04 | Put "can the driver do this now" rules on the model: `canAnswerOffer`, `canClaimRide`, and `canTakeRideStep` | `canChangeAvailability` already lived there, while views combined state for the rest. Each rule now has tests, and every screen asks the same way. |
| 2026-11-04 | Share the main button as a `PrimaryActionButton` view, and the tap guard as `ignoresTapsBriefly(after:)` | The button's look and the 0.75-second guard were copied into three views. A custom `ButtonStyle` was considered, but it would have had to redraw the system's bordered style. The button reads whether it's enabled from the environment, so the guard dims it too. Accept sets its own accessibility value from outside, which a temporary test confirmed replaces the button's. |
| 2026-11-04 | Move `RootView`'s navigation rules into an `AppNavigation` struct (revises the untested navigation noted in "Return to the screens the driver left…") | The rules had no tests. A value type in `@State` can be tested with no model or timing, where an `@Observable` class would add shared state for something one view owns. Mutation checks found two rules no test covered, which now have tests. |
| 2026-11-04 | Pull `WaitingList`, `SubscriberList`, and one timer helper out of `MockRideService`, and keep its lint exceptions (revises "Turn off SwiftLint's `file_length` rule…") | Each has rules of its own and now has tests. The file shrank from 621 to 593 lines, still over both limits. What remains changes the ride, driver, and offer together on one actor, which is what makes each request atomic. |
| 2026-11-04 | Add folders for `Model/`, `Debug/`, `Features/Connection/`, and `FarelineTests/TestSupport/` | `App/` held the entry point, the model, debug tooling, and display text together. |
| 2026-11-04 | Add a String Catalog for plural text (revises "Write singular and plural text in code, in `PastRideFilter`") | The catalog's plural variations replace singular cases written by hand in four places. Zero cases stay in code, as they're different sentences rather than plural forms. Every other string is synced in, so building in Xcode doesn't change the file. |
| 2026-11-04 | Keep Debug-only and preview text out of the String Catalog (corrects "Add a String Catalog for plural text") | That entry said building in Xcode doesn't change the catalog. It did: Xcode re-sorted it and dropped the Demo menu's titles and a preview's placeholder, for a reason that wasn't found. That text is now marked as not for translation, so no build adds or removes it. A developer tool and preview text never needed translating. |
| 2026-11-04 | Show the app with four light mode screenshots and one in dark mode, rather than a recording | GitHub shows images reliably at a glance, each has alt text, and they're small. A temporary UI test captured them and isn't kept, so #17 runs one again if the screens change. In exchange, the README doesn't show motion, such as an offer arriving. |
| 2026-11-04 | Order the README for a reviewer: what it looks like, how to run and try it, then the design | A reviewer can run the app before reading the reasoning, and every feature has steps to reach it. The design section covers the assignment's questions, and links to this log for the rest. |
| 2026-11-04 | Use `textSecondary` for Past Rides' count header and Waiting Riders' footer | The system's header gray fell just short of contrast in light mode. The audits hadn't caught it, as they run in whichever appearance the simulator is in, and it had been in dark mode. The token is checked in both modes by `ColorTokenTests`. |
| 2026-11-04 | Run every accessibility audit in light and dark mode | The audits ran in whichever appearance the simulator was in, which let a light mode contrast problem go unseen until #10. Each test now sets the appearance through `XCUIDevice` and restores it afterwards. In exchange, the UI tests take about four minutes rather than two and a half. |
| 2026-11-04 | Shorten the clean-clone check to a fresh clone built from the terminal, a search for private details, and a look at the public page | Xcode compiles every file in the project's folders, committed or not, so a fresh clone is what catches a missing file. Cloning without credentials, a full walkthrough, and a second person were dropped, as a private browser window and the user's earlier review cover them. |
| 2026-11-04 | Don't add a screen recording | The screenshots meet the assignment, and the app hasn't changed since they were taken. |

## Open questions

Decide these in the issue noted, then record the outcome in the decision log.

None are open. #15's question, which actions queue offline and how conflicts resolve, is answered in the decision log.

## Deliverables checklist

- [ ] Public GitHub repository, with the link sent to the recruiting contact
- [x] Clear build and run instructions
- [ ] Clean-clone check passed: the public repo clones and runs using only the README (see #17)
- [x] One screenshot or a short recording of the primary flow
- [x] README design section covering:
  - [x] Architecture and state management
  - [x] At least one real trade-off
  - [x] What I'd change or add with more time
  - [x] Simplifying assumptions
  - [x] AI tools used and how
