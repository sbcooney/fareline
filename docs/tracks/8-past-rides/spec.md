# #8: Review past rides

Issue: https://github.com/sbcooney/fareline/issues/8

## Goal

The driver can look back at the rides they've given, including after relaunching the app, and open any one for its details.

## Behavior

### Opening past rides

The driver opens Past Rides from the home screen while they're offline or available. It's a pushed screen, through `AppDestination.pastRides`, replacing today's placeholder view.

Tests:
- Checked in the simulator: the home screen links to Past Rides, and the back button returns to it.

### Past rides list

The list shows the driver's past rides, newest first by when they ended. Each row shows the route (pickup to drop-off), when it ended, and the fare, or "Cancelled". It reads the model's session, so it's always current.

Tests:
- The service lists past rides newest first by when they ended, across completed and cancelled rides if both are shown.
- A ride can't end while the list is open: the list is only reachable while the driver is offline or available, and a new offer returns them to the root screen.

### Empty state

With no past rides, the screen says so and explains that finished rides will appear there.

Tests:
- Checked in the simulator: a driver with no past rides sees the empty state, not an empty list.

### Ride detail

Tapping a ride shows its rider, pickup, drop-off, fare, when it was requested, and how and when it ended.

Tests:
- Looking up a past ride by ID returns that ride, even after newer rides are added.
- Looking up an ID that isn't a past ride returns nothing, and the detail screen shows that the ride isn't available rather than crashing.
- Checked in the simulator: the detail screen for a completed ride and, if shown, a cancelled one.

### Surviving relaunch

Past rides are saved after each ride ends, and are there after the app is quit and relaunched.

Tests:
- Saved rides load back unchanged, round-tripping every persisted field, including the end time and `driverID`.
- Each persisted status round-trips: `completed` and, if decided below, `cancelled`.
- Loading rejects a saved ride whose state the domain doesn't allow, such as `completed` with no end time, or a past ride with no driver, and doesn't crash.
- A missing file starts with no past rides. An unreadable file also starts empty, and isn't overwritten until a new ride ends.
- A ride is saved as soon as it ends, by completion or cancellation.
- Rides loaded at launch don't show a "Ride Cancelled" alert, because the model ignores past rides in its first session.

### Offers on pushed screens

A new offer must be seen even when the driver is on Past Rides or a ride's detail screen. Today, offers replace only the root screen, so a pushed screen would hide one.

Tests:
- Checked in the simulator: an offer arriving while a screen is pushed brings the driver to the offer. The navigation path lives in a view, so a unit test can't reach it.

## Out of scope

- Filtering, searching, or grouping history by day. Not needed for a short list.
- Earnings totals.
- Syncing history with a backend, and offline use of it (#15).
- Whether offers should take over the screen at all (#9).

## Decisions

Decided on 2026-11-03 and recorded in the decision log in docs/PLAN.md:

- `MockRideService` saves past rides, through `PastRideStore`, a JSON file whose location is injected.
- `Codable` JSON rather than SwiftData. Decoding replays `driverAssigned` and the later steps through `apply(_:)`, and rejects anything that fails.
- Cancelled rides are shown, labeled "Cancelled", with no fare.
- `endedAt` replaces `completedAt`, and `.cancelled` takes a date.
- `RootView` holds the navigation path, and clears it when an offer arrives.
- `Features/PastRides/`, with `PastRidesView`, `PastRideRow`, `PastRideDetailView`, `AppDestination.pastRide(Ride.ID)`, and a "Past Rides" toolbar button.
