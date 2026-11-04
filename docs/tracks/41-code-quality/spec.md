# #41: Code quality pass before submission

Issue: https://github.com/sbcooney/fareline/issues/41

## Goal

Fix what a Swift expert reviewing the whole project would flag: copied view code, rules that live in views, an untested navigation path, a clock read directly, a model and mock that do too much, folders that mix concerns, plurals written by hand, and comments that restate the code. Nothing the driver sees changes.

## Behavior

### Ride end times come from the injected clock

`DriverModel(service:timeSource:)` takes a `TimeSource`, defaulting to `SystemTimeSource()`. Completing or cancelling a trip, online or queued offline, records that source's time.

Tests:
- Completing a trip offline and replaying it records exactly the manual time source's time.
- Cancelling offline records the time source's time.

### The model answers what the driver can do now

`canClaimRide`, `canAnswerOffer`, and `canTakeRideStep` sit beside `canChangeAvailability`, and views read them rather than combining state themselves.

Tests:
- `canAnswerOffer` is false during a request and offline, and true otherwise with an offer.
- `canClaimRide` is true only when available, online, and not mid-request.
- `canTakeRideStep` is false during a request, and stays true offline, as steps queue.

### Main buttons share one view, and the tap guard is one modifier

`PrimaryActionButton` draws the filled button with a progress state, and dims its text whenever it's disabled, however that happens. `ignoresTapsBriefly(after:)` disables a view for 0.75 seconds each time a value changes. Go Online/Offline, the ride step, and Accept/Decline use them, and look and behave as before.

Tests:
- No unit test: both hold view state. Verified by screenshots from a temporary test, and by the existing accessibility audits and offer UI tests.

### Navigation rules are a tested value type

`AppNavigation` holds the path, the path left to open an offer, and whether the ride came from Waiting Riders. `RootView` calls it from its `onChange` handlers.

Tests:
- Opening an offer from a pushed screen saves the path and returns to the root.
- An offer ending without a ride puts the saved path back. One ending with a ride doesn't.
- A ride starting clears the path, and remembers when it started from Waiting Riders.
- The driver cancelling that ride before the trip returns to Waiting Riders. A rider's cancellation, a completed trip, or a cancellation after the trip started return to the home screen.
- A ride started from another screen doesn't return to Waiting Riders.

### Queued steps show through a pure function

`DriverSession.applying(_ steps: [PendingRideStep])` returns the session with the steps applied to its ride. The model calls it.

Tests:
- No steps returns the session unchanged.
- A step moves the active ride on.
- A completion or cancellation moves the ride to past rides and frees the driver.
- A step that no longer applies, or is for another ride, is skipped.

### The mock is smaller, and behaves as before

`SubscriberList<Element>` replaces the two subscriber dictionaries, one private helper runs the four timers, and `WaitingList` holds the passed-over rides and their ordering.

Tests:
- `SubscriberList` sends to every subscriber, and stops sending to one that's removed.
- `WaitingList` lists only rides still awaiting a driver, longest wait first, with ties broken by ID.
- Every existing mock test still passes.

### Folders separate concerns

`Model/`, `Debug/`, `Features/Connection/`, and `FarelineTests/TestSupport/` are added, and `RideServiceError+Message` becomes `RideServiceError+Display` in `Features/Shared/`.

Tests:
- None: moves only. The build and every test still passing confirms them.

### Plurals come from a String Catalog

`Localizable.xcstrings` gives the singular and plural for the toast, the status popover, and the past rides count, replacing their hand-written cases.

Tests:
- The existing message tests still read the same English text for 0, 1, and many.

### Comments say why

Comments that only restate the code are removed, and every one that explains a reason stays.

Tests:
- None: reading. The build and lint still pass.

## Out of scope

- Any change the driver can see.
- The README (#10).

## Decisions

Decided with the user on 2026-11-04:

- File #41 for this, before #10.
- `PrimaryActionButton` as a view rather than a `ButtonStyle`, since a style can't build on `.borderedProminent`, and `ignoresTapsBriefly(after:)` as a modifier.
- `canClaimRide`, `canAnswerOffer`, and `canTakeRideStep` on the model.
- `DriverModel(service:timeSource:)`, reusing `TimeSource`.
- `AppNavigation` as a struct in `RootView`'s `@State`, not an `@Observable` class.
- The folders above.
- `DriverSession.applying(_:)` rather than a new type.
- `SubscriberList<Element>`, a timer helper, and `WaitingList` in the mock. The lint exceptions go only if the file fits.
- A String Catalog, and a comment pass last.
