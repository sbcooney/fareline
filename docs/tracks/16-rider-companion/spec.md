# #16: Rider Companion readiness

Issue: https://github.com/sbcooney/fareline/issues/16

## Goal

Confirm the finished code could support a future Rider Companion app, fix the one place where its naming says otherwise, and document in the README what a rider app would reuse, what it would add, and when shared code should move to a Swift package. No rider app code is built.

## Audit findings

The audit read every file in `Fareline/Domain/` and `Fareline/Services/`, and the parts of `Fareline/App/` and `Fareline/Features/` that touch them.

### Ready as is

- **Domain has no app dependencies.** Every domain file imports only Foundation. Nothing in `Domain/` refers to the model, the service, or SwiftUI.
- **Ride names describe the ride, not the driver.** `RideStatus` (`driverEnRoute`, `driverArrived`, `inProgress`) and `RideEvent` read the same from either side. `RideRole` names who cancelled without a point of view.
- **Rules for both parties live in the domain.** `RideStatus.applying(_:)` already holds the rider's rule, cancelling until the trip starts, and `canBeCancelled(by:)` answers it for either role.
- **Driver wording lives in the app.** "Heading to Pickup", "I've Arrived", and "Cancelled by You" are in `Features/Shared/` display extensions, documented as the driver's point of view. A rider app would write its own, such as "Driver on the way", from the same statuses.
- **Rider actions already exist in the mock, as simulations.** `simulateRideCancelled(id:)` is what a rider's cancel would call, so the mock already applies the rider's side of the rules.
- **The conventions carry over.** Complete, versioned snapshots, `connectionUpdates()`, typed `RideServiceError`s, and the injected `TimeSource` don't depend on who the client is.

### Not ready: the service contract's name

`RideService` sounds shared, but every method is a driver action: going online, answering offers, ride steps, claiming from the list. It returns a `DriverSession`, and its doc says the current driver is implied. `docs/PLAN.md` says "a rider client could use the same contract", which isn't true: a rider needs to request a ride, cancel it, and follow it, and needs a session holding their own ride rather than offers and a waiting list.

### Gaps a rider app would fill, documented rather than built

- **Who the driver is.** `Ride` holds only `driverID`. A rider needs the driver's name and vehicle, which a rider session would carry.
- **A rider's history.** `PastRideStore` rejects rides with no driver, which is right for a driver's history. A rider's would include rides they cancelled before a driver was assigned.
- **Requesting a ride.** The mock creates requests itself through `MockRideData`. A rider service would create them from the rider's request.

## Behavior

### The driver's service contract is named for the driver

The protocol is renamed `DriverService`, so its name pairs with `DriverSession` and `DriverModel`, and leaves room for a rider contract beside it. Nothing the driver sees changes, and no method changes.

Tests:
- No new tests: this is a rename with no behavior change. The existing 187 unit tests and 10 UI tests must still pass, and the compiler catches any missed use.

### The plan no longer says the contract is shared

`docs/PLAN.md`'s "Rider Companion considerations", Architecture, and Services sections describe the driver's contract, and what a rider contract would be.

Tests:
- None: documentation. Verified by reading.

### The README explains the Rider Companion readiness

A README section, "Ready for a Rider Companion", covers:
- What a rider app reuses: the domain types and rules, the service conventions, and the mock backend.
- What it adds: a rider contract and session, sketched as a short list of methods, its own display wording, and the gaps above.
- The naming choices made with a rider app in mind, such as `driverEnRoute` over `goingToPickup`, `RideRole`, and the renamed contract.
- When domain code should move to a shared Swift package, and why it hasn't yet.

Tests:
- None: documentation. Verified by reading, and every type or method it names is checked against the code.

## Out of scope

- Any rider app code, including a rider protocol, session type, or target. The README sketches them only.
- A shared Swift package. The README says when to create one.
- The rest of the README, such as screenshots and future work, which is #10.

## Decisions

Decided with the user on 2026-11-04, and recorded in the decision log:

- The protocol is renamed `DriverService`, pairing with `DriverSession` and `DriverModel`.
- `MockRideService` and `RideServiceError` keep their names: the mock plays the whole backend, and most errors apply to either client.
- The README describes when to move to a shared package, once a second app exists, rather than creating one. Discussing it, not doing it, suits a take-home.
