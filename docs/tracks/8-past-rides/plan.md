# Plan for #8: Review past rides

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work. The phases assume the recommendations in the spec's "Decisions needed". Revise them once those are decided.

## Phase 1: Saving and loading past rides

- [ ] Write failing tests: round trip of every persisted field and status; rejected invalid state, including a past ride with no driver; a missing or unreadable file starts empty
- [ ] Add `Codable` to the domain types that are saved, with decoding that replays the ride's events through `apply(_:)`
- [ ] Add the file-saving type, writing to a file in Application Support
- [ ] Verify: the tests pass, and removing the validation makes the invalid-state test fail

## Phase 2: The service keeps history across launches

- [ ] Write failing tests: a service created with saved rides starts with them in `pastRides`; a completed or cancelled ride is saved
- [ ] Load saved rides when `MockRideService` is created, and save after each ride ends
- [ ] Verify: the tests pass, and in the simulator a completed ride is still listed after relaunch

## Phase 3: Past rides list and detail

- [ ] Write failing tests: the service lists past rides newest first, by when they ended; looking up a ride by ID
- [ ] Add `PastRidesView`, `PastRideRow`, and `PastRideDetailView`, and the `AppDestination.pastRide(Ride.ID)` case
- [ ] Link Past Rides from the home screen's toolbar, and replace the placeholder view
- [ ] Verify: simulator screenshots of the list, the empty state, and completed and cancelled detail screens, at default and the largest text sizes, in light and dark mode. A ride that ends while the list is open appears at the top

## Phase 4: Offers on pushed screens

- [ ] No unit test: the navigation path lives in `RootView`
- [ ] Hold the navigation path in `RootView`, and clear it when an offer arrives
- [ ] Verify: in the simulator, an offer arriving on Past Rides shows the offer

## Before the PR

- [ ] Review with the relevant Swift skills, as listed in "Development flow" in docs/PLAN.md
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: status, decision log, assumptions, and any outdated sections
