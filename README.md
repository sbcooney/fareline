# Fareline

A simplified rideshare app for drivers, built with Swift and SwiftUI.

🚧 In development. See the [project plan](docs/PLAN.md) for current status.

## Requirements

- Xcode 27.2 or later
- An iPhone simulator running iOS 27.2 or later

The app has no third-party dependencies and needs no API keys or sign-in.

## Build and run

Open `Fareline.xcodeproj` in Xcode, select an iPhone simulator running iOS 27.2 or later, and press **Cmd+R**.

To run on a physical iPhone, select your own team and a unique bundle identifier under **Signing & Capabilities**. The simulator needs neither.

## Simulating no connection

The app has no real network, so a **Demo** menu lets you lose and restore the connection. It's the wrench button at the top left of the main screen, whether that's showing your status, an offer, or your current ride, and it's in Debug builds only, which is what Xcode runs.

- **Simulate No Connection** cuts the app off from the mock service. Requests fail and no updates arrive, while the service's own world keeps going, so offers still expire and riders still cancel.
- **Restore Connection** reconnects. The app receives everything that changed meanwhile, then sends any ride steps you took offline, in order.

Losing the connection is usually brief, so a toast says so for a few seconds over the top of the screen, without moving anything. It also confirms each ride step saved offline, and says when the connection is back. While there's no connection, a wifi-slash button stays in the navigation bar, with a badge counting the ride steps waiting. Tap it for what works without a connection. VoiceOver announces each change.

What works with no connection:

- **Your own ride's steps:** I've Arrived, Start Trip, Complete Trip, and Cancel Ride. Each shows straight away and is sent when the connection returns. A completed or cancelled trip keeps the time you tapped.
- **Reading:** your current ride, Past Rides, and Waiting Riders, as last received.

What needs a connection, and is disabled with a line saying so: going online or offline, accepting or declining an offer, and taking a ride from Waiting Riders. Each needs a live answer from the service.

To try it:

1. Tap **Go Online**, and accept the offer that arrives.
2. From the Demo menu, choose **Simulate No Connection**.
3. Tap **I've Arrived**, then **Start Trip**. The ride moves on, a toast confirms each step is saved, and the bar's badge shows 2.
4. Choose **Restore Connection**. A toast says 2 ride steps are being sent, the bar's button goes away, and the service records both steps.

To see a conflict, decline offers until one from **Will Cancel** arrives, and accept it. Will Cancel cancels 10 seconds after you accept. Lose the connection straight away and tap **I've Arrived**. After 10 seconds, restore the connection: the service refuses the step, as the rider has cancelled, and you're told the rider cancelled. If the service refuses a queued step for another reason, the steps after it are dropped, the ride shows as the service has it, and you're told your offline steps couldn't all be sent.

## Run the tests

In Xcode, press **Cmd+U**. This runs both test targets:

- **`FarelineTests`:** unit and integration tests in Swift Testing. They take under a second.
- **`FarelineUITests`:** UI tests in XCTest, which Swift Testing doesn't support. They run Apple's accessibility audit on every screen at the default and largest text sizes, and check how offers reach the driver. They take a few minutes.

From the terminal, replace `iPhone 18 Pro` with any iPhone simulator you have on iOS 27.2 or later. To see which ones are available, run `xcrun simctl list devices available`.

```sh
xcodebuild test \
  -project Fareline.xcodeproj \
  -scheme Fareline \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

To run only the unit tests, add `-only-testing:FarelineTests`.

## Lint

[SwiftLint](https://github.com/realm/SwiftLint) is optional and runs separately from the build, so you don't need it to build the app:

```sh
swiftlint lint
```

## Design system and artwork

Colors are named tokens in the asset catalog, each with a light and dark value, such as `brandPrimary` and `textSecondary`. Views use only tokens, so changing a token changes every screen that uses it. `ColorTokenTests` checks every text and background pair against WCAG AA contrast in both modes.

The app icon and launch mark are drawn by a script from the same tokens. After changing a brand color, regenerate them from the repository root:

```sh
swift scripts/generate-artwork.swift
```

## Ready for a Rider Companion

The assignment says a Rider Companion app may follow. No rider code is built, but the code was audited so that one could be added without reworking the driver app.

**What a rider app would reuse:**

- **The domain, unchanged.** `Domain/` imports only Foundation and knows nothing of the app, the service, or SwiftUI. Ride statuses describe the ride rather than the driver's view of it, such as `driverEnRoute` rather than `goingToPickup`, so a rider reads the same values. `RideRole` records who cancelled without taking a side.
- **The rules for both parties.** The ride's lifecycle already holds the rider's rule, cancelling until the trip starts, and `RideStatus.canBeCancelled(by:)` answers it for either role. Ride state is separate from the driver's availability, which a rider never needs.
- **The service's conventions.** Complete, versioned snapshots, `connectionUpdates()`, typed `RideServiceError`s, and the injected `TimeSource` don't depend on who the client is.
- **The mock backend.** `MockRideService` plays the whole backend, riders included: `simulateRideCancelled(id:)` already applies a rider's cancellation through the domain's rules. A rider contract would be a second conformance on the same actor.

**What it would add:**

- **Its own contract and session.** The driver's contract is `DriverService`, returning a `DriverSession`. It was renamed from `RideService`, which sounded shared, though every method is a driver action. A rider app would add a `RiderService` beside it, with methods such as `requestRide(pickup:dropoff:)`, `cancelRide(rideID:at:)`, and `sessionUpdates()`, and a `RiderSession` holding the rider's current ride and history, with no offers or waiting list.
- **Who the driver is.** A ride holds only its driver's ID. A rider needs the driver's name and vehicle, which the rider session would carry.
- **A rider's history.** Saved past rides must have a driver, which suits a driver's history. A rider's would include rides they cancelled before any driver was assigned.
- **Its own wording.** Text such as "Heading to Pickup" and "Cancelled by You" lives in the driver app's display extensions, not the domain, so a rider app would write its own, such as "Driver on the way", from the same statuses.

**When to move to a shared package:** once a second app target exists, and not before. The package would hold `Domain/`, both service contracts with their sessions, and the mock, so each app could build and demo against it. With one app, a package adds cost and no benefit: every shared type and method would need to be `public`, and the package would need its own test target. Because the domain already depends on nothing in the app, the move would be mechanical.

## AI tools used and how

The app was built with Claude Code, with a person directing each step and reviewing every change. The workflow:

- **A spec and plan for each issue.** Before any code, the `/start-issue` project skill reads the GitHub issue and writes a spec (the expected behavior and the cases the tests must cover) and a plan (phases with failing tests first and a verify step) in `docs/tracks/`. A person reviews both and settles open questions before work starts. Tracks begin with #8, so earlier issues don't have one.
- **Swift skills.** Skills for SwiftUI, Swift Concurrency, and Swift Testing are loaded while writing code, then used to review it before each PR. Their suggestions are weighed rather than applied automatically, and the toolchain wins when they disagree.
- **Automated review.** `/code-review` checks each PR for correctness bugs, and `/simplify` checks larger changes for over-engineering. Each finding is fixed or recorded with a reason in the PR.
- **Review by a person.** Every PR is read, questioned, and merged by a person, who must be able to explain all of the code.
- **Lessons file.** `CLAUDE.md` holds rules for the agent. A mistake it makes twice becomes a rule there, with the reason.

## What I'd change or add with more time

These would help a larger project, but would cost more than they return here:

- **Living specs with OpenSpec,** in place of per-issue tracks. Specs that stay current describe the whole system rather than one change, but need tooling and a custom workflow to be worth it.
- **Parallel agents in separate git worktrees,** so independent issues can progress at once. Here, issues are worked one at a time so each can be reviewed closely.
- **CI** that runs the tests and SwiftLint on every PR. Here, both run locally before each PR.
- **Automated pre-PR gates as skills,** such as a single skill that runs the tests, lint, and reviews, and refuses to open a PR until they pass. Here, the plan's checklist does this by hand.
