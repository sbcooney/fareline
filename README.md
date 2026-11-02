# Fareline

A simplified rideshare app for drivers, built with Swift and SwiftUI.

🚧 In development. See the [project plan](docs/PLAN.md) for current status.

## Requirements

- Xcode 27.2 or later
- iOS 27.2 simulator

The app has no third-party dependencies and needs no API keys or sign-in.

## Build and run

Open `Fareline.xcodeproj` in Xcode, select an iOS 27.2 iPhone simulator, and press **Cmd+R**.

## Run the tests

In Xcode, press **Cmd+U**. From the terminal:

```sh
xcodebuild test \
  -project Fareline.xcodeproj \
  -scheme Fareline \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2'
```

## Lint

[SwiftLint](https://github.com/realm/SwiftLint) is optional and runs separately from the build, so you don't need it to build the app:

```sh
swiftlint lint
```
