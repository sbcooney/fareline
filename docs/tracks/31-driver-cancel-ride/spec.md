# #31: Let the driver cancel their current ride

Issue: https://github.com/sbcooney/fareline/issues/31

## Goal

A driver can get out of a ride at any stage, such as when a rider doesn't show up, a pickup is unsafe, or the car breaks down. A warning explains what cancelling means before anything is sent, so a ride is never cancelled by accident. Every ride records who cancelled it, so the driver's history and a future rider app can tell the two apart.

## Behavior

### The driver can cancel at every stage

The current ride screen has a Ride Options menu at the top while heading to pickup, at pickup, and on trip, with Cancel Ride in it. Choosing it opens a confirmation, attached to the menu, that explains the consequence for that stage. Nothing is sent until the driver confirms. Choosing Keep Ride closes the confirmation and leaves the ride as it was.

Tests:
- The confirmation's wording for each of the three stages. (Parameterized over the stages.)
- Confirming sends the cancellation for the ride on screen, not whichever ride is current by then.
- Checked in the simulator, with screenshots: the confirmation opens from the menu, tapping outside it changes nothing, and Cancel Ride returns the driver to the available screen.
- The accessibility audit passes on the ride screen with the new menu.

### Cancelling ends the ride and frees the driver

After a confirmed cancellation, the ride is `cancelled`, records that the driver cancelled it and when, and moves to Past Rides. The driver is available again and gets offers as usual. The driver sees no "Ride Cancelled" alert, because they cancelled it themselves.

Tests:
- Cancelling while heading to pickup, at pickup, and on trip each leaves the ride `cancelled` by the driver, with an end time, at the top of past rides. (Parameterized over the stages.)
- The driver becomes available, and a next offer is scheduled.
- The saved history includes the cancelled ride.
- A driver's cancellation doesn't show the rider-cancelled alert.
- A ride cancelled by each party, including on trip, decodes from the saved file. A damaged one, such as a driver's cancellation with no driver, or a completed ride with a canceller, is rejected.

### A rider still can't cancel once the trip has started

The rules for riders don't change: a rider can cancel while their driver is heading to pickup or at pickup, but not on trip.

Tests:
- A rider cancelling an in-progress ride is rejected, and the ride is unchanged.
- A rider cancelling while the driver is at pickup ends the ride at the service level: the ride is `cancelled` by the rider, it's in past rides, and the driver is available. This is the case the issue says only domain tests cover today.

### Past Rides shows who cancelled

A cancelled ride in Past Rides says whether the rider or the driver cancelled it, in the row and in the detail screen. Neither shows a fare.

Tests:
- The label for each canceller. (Parameterized.)
- Checked in the simulator: one ride cancelled by each party, in the list and the detail screen.

### A cancellation that fails or loses a race leaves things consistent

If the request fails, the driver sees an error and the ride is unchanged. If the ride ended first, the driver sees the explanation that matters, and never two alerts.

Tests:
- A failed cancellation shows the error, and the ride is still active at the same stage.
- The rider cancels while the driver's cancellation is in flight: the driver sees only the rider-cancelled alert, and the ride is recorded as cancelled by the rider.
- The driver cancels just before the rider's scheduled cancellation would run: the rider's cancellation has no effect, and the ride stays cancelled by the driver.
- A step, such as Start Trip, can't be sent while a cancellation is in progress, and the reverse, because the controls are disabled during any request.

## Out of scope

- A partial fare for a trip ended early. The mock has no distance travelled, so a driver who cancels on trip earns nothing, and the confirmation says so.
- Telling the rider, or offering their ride to another driver. #16 audits what a rider app would need, and the service records who cancelled so it has that.
- Any effect on the driver's standing, such as a cancellation rate. Nothing in the app tracks it.

## Decisions

Decided on 2026-11-03 and recorded in the decision log in docs/PLAN.md:

- A cancellation records who cancelled: `RideEvent.cancelled(by: RideRole, date: Date)`, with a new `RideRole` enum of `rider` and `driver`, and `Ride.cancelledBy`.
- Only the driver can cancel on trip, and earns no fare. The driver can still end a trip with the full fare through Complete Trip.
- The service and the model each get `cancelRide(rideID:)`, taking the ride's ID like the other ride steps.
- The control is a "Ride Options" menu (⋯) at the top right, holding a red "Cancel Ride". It keeps cancelling, which is rare and can't be undone, away from the step button. While cancelling, a spinner replaces the ⋯.
- The confirmation is titled "Cancel This Ride?", with "Cancel Ride" (destructive) and "Keep Ride". Its message, by stage:
  - Heading to pickup and at pickup: "You won't earn the fare for this ride, and the rider will need to find another driver."
  - On trip: "The rider is with you. You won't earn the fare for this trip, so end it this way only if you can't complete it."
- A cancelled ride saved without `cancelledBy`, from before this change, is read as cancelled by the rider.
- Past Rides says "Cancelled by Rider" or "Cancelled by You".
- No alert or announcement after the driver cancels, beyond returning to the available screen.
