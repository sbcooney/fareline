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

## Run the tests

In Xcode, press **Cmd+U**. From the terminal, replace `iPhone 18 Pro` with any iPhone simulator you have on iOS 27.2 or later. To see which ones are available, run `xcrun simctl list devices available`.

```sh
xcodebuild test \
  -project Fareline.xcodeproj \
  -scheme Fareline \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

## Lint

[SwiftLint](https://github.com/realm/SwiftLint) is optional and runs separately from the build, so you don't need it to build the app:

```sh
swiftlint lint
```

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
