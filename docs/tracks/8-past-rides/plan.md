# Plan for #8: Review past rides

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work. The phases follow the decisions in the spec.

## Phase 1: A ride records when it ended

- [x] Write failing tests: completing and cancelling both set the end time; the end time is unchanged by a rejected event
- [x] Replace `completedAt` with `endedAt`, and give `.cancelled` a date, updating the mock service and existing tests
- [x] Verify: all tests pass, and the service lists past rides newest first by when they ended

## Phase 2: Saving and loading past rides

- [x] Write failing tests: round trip of every persisted field and status; rejected invalid state, including `completed` with no end time and a past ride with no driver; a missing file starts empty; an unreadable file starts empty and isn't overwritten until a ride ends
- [x] Add `Codable` to the domain types that are saved, with decoding that replays the ride's events through `apply(_:)`
- [x] Add `PastRideStore`, writing JSON to a file whose location is injected
- [x] Verify: the tests pass, and removing the validation makes the invalid-state tests fail

## Phase 3: The service keeps history across launches

- [ ] Write failing tests: a service created with saved rides starts with them in `pastRides`; a completed and a cancelled ride are each saved when they end; a model's first session with saved rides shows no cancellation alert
- [ ] Load saved rides when `MockRideService` is created, and save each time a ride ends. The app uses Application Support, and tests use a temporary folder
- [ ] Verify: the tests pass, and in the simulator a completed ride is still listed after relaunch

## Phase 4: Past rides list and detail

- [ ] Write failing tests: looking up a past ride by ID, including after newer rides are added and for an unknown ID
- [ ] Add `PastRidesView`, `PastRideRow`, and `PastRideDetailView` in `Features/PastRides/`, and the `AppDestination.pastRide(Ride.ID)` case
- [ ] Link Past Rides from the home screen's toolbar, and replace the placeholder view
- [ ] Verify: simulator screenshots of the list, the empty state, and completed and cancelled detail screens, at default and the largest text sizes, in light and dark mode. A ride that ends while the list is open appears at the top

## Phase 5: Offers on pushed screens

- [ ] No unit test: the navigation path lives in `RootView`
- [ ] Hold the navigation path in `RootView`, and clear it when an offer arrives
- [ ] Verify: in the simulator, an offer arriving on Past Rides or a detail screen shows the offer

## Before the PR

- [ ] Review with the relevant Swift skills, as listed in "Development flow" in docs/PLAN.md
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: status, decision log, assumptions, the open questions for #8, and the `Features/` folder names in "Project structure"
