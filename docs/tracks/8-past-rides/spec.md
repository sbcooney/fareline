# #8: Review past rides

Issue: https://github.com/sbcooney/fareline/issues/8

## Goal

The driver can look back at the rides they've given, including after relaunching the app, and open any one for its details.

## Behavior

### Past rides list

The driver opens Past Rides from the home screen. It lists their past rides, newest first. Each row shows the date, the route (pickup to drop-off), and the fare.

Tests:
- The service lists past rides newest first, by when they ended.
- A ride that ends while the list is open appears at the top. The list reads the store's session, so this is checked in the simulator.

### Empty state

With no past rides, the screen says so and explains that completed rides will appear there.

Tests:
- Checked in the simulator: a driver with no past rides sees the empty state, not an empty list.

### Ride detail

Tapping a ride shows its rider, pickup, drop-off, fare, when it was requested, and how and when it ended.

Tests:
- Looking up a ride by ID returns that ride, even after newer rides are added.
- Checked in the simulator: the detail screen for a completed ride and for a cancelled one.

### Surviving relaunch

Past rides are saved, and are there after the app is quit and relaunched.

Tests:
- Saved rides load back unchanged, round-tripping every persisted field, including `completedAt` and `driverID`.
- Each persisted status round-trips: `completed` and, if decided below, `cancelled`, with the driver assigned.
- Loading rejects a saved ride whose state the domain doesn't allow, such as `completed` with no `completedAt` or no driver, or a past ride with no driver, and doesn't crash.
- A missing or unreadable file starts with no past rides rather than failing.
- Saving happens after each ride ends, so a ride isn't lost if the app quits right after.

### Offers on pushed screens

A new offer must be seen even when the driver is on Past Rides or a ride's detail screen. Today, offers replace only the root screen, so a pushed screen would hide one.

Tests:
- Checked in the simulator: an offer arriving while a screen is pushed brings the driver to the offer. The path lives in a view, so a unit test can't reach it.

## Out of scope

- Filtering, searching, or grouping history by day. Not needed for a short list.
- Earnings totals.
- Syncing history with a backend, and offline use of it (#15).
- The broader question of whether offers should take over the screen (#9).

## Decisions needed

- **Where are past rides saved?** Recommendation: in `MockRideService`, which plays the backend, because the session already delivers `pastRides` and the app stays a renderer of what the service sends. The alternative is an app-side cache in `DriverStore`, which #15 will want, but the mock starts empty on each launch, so the app would have to merge its cache with the service's history now rather than in #15.
- **`Codable` JSON file or SwiftData?** Recommendation: a JSON file with `Codable`, because domain types are value types with rules enforced through `apply(_:)`, and SwiftData would need separate `@Model` classes that mirror them. Decoding validates by replaying the ride's events through the domain, so invalid saved state is rejected.
- **Show rides the rider cancelled?** Recommendation: yes, labeled "Cancelled" with no fare, because the driver did drive toward the pickup and may want to see it.
- **When did a cancelled ride end?** `Ride` stores `completedAt` but no cancellation time, so a cancelled ride can't be sorted by when it ended or show that time. Recommendation: replace `completedAt` with an `endedAt` that `.tripCompleted(date:)` and a new `.cancelled(date:)` both set, because the status already says how the ride ended. This changes a domain event, so it's a decision rather than a detail.
- **What does decoding check?** `Ride` doesn't store its events, so decoding infers them from the saved fields. A driver's past ride always had a driver assigned, so recommendation: replay `driverAssigned` and then the steps that lead to the saved status, and reject anything that fails, including a past ride with no driver.
- **How does an offer reach a driver on a pushed screen?** Recommendation: `RootView` holds the navigation path, and clears it when an offer arrives, returning the driver to the offer. This revisits nothing until #9 decides whether offers take over the screen.
- **Names.** Proposed: `PastRidesView`, `PastRideRow`, `PastRideDetailView` in `Features/PastRides/`, a new `AppDestination.pastRide(Ride.ID)` case, and a toolbar button labeled "Past Rides" on the home screen. The file-saving type would be named once the first decision is made.
