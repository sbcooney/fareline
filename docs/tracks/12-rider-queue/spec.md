# #12 and #13: See a queue of waiting riders, and self-assign to a ride

Issues: https://github.com/sbcooney/fareline/issues/12 and https://github.com/sbcooney/fareline/issues/13

The two issues are done together in one PR. #13 was split from #12 only to keep PRs small, and a queue the driver can't act on isn't useful on its own.

## Goal

Offers keep arriving as they do now. In addition, the driver can see the riders that no driver has taken, longest wait first, and take one of those rides themselves. If another driver gets there first, the driver is told clearly and sees the list as it is now.

## Behavior

### New rides are offered first

Every new ride request goes out as an offer first, as today. The list is only for rides that an offer didn't place, so a ride that's being offered, to this driver or any other, is never in the list.

Tests:
- A new ride that's offered to this driver isn't in the list.
- An offer's ride joins the list when this driver declines the offer.
- An offer's ride joins the list when the offer expires.
- An offer's ride joins the list when the driver goes offline while it's showing.

### The list holds rides no driver took

A waiting ride is in the list once an offer for it has been declined, has expired, or ended because the driver went offline, or once the driver who accepted it cancelled before the trip started. The session includes the list, longest wait first. A ride leaves the list as soon as any driver takes it or its rider cancels, in the same session that reports the change. Rides in the list aren't offered again, as the driver can already see and take them.

Tests:
- The session lists waiting rides, longest wait first.
- A ride leaves the list when another driver takes it, and when its rider cancels.
- A ride in the list isn't offered again.

### A driver's cancellation puts the rider back in the list

When the driver cancels while heading to pickup or at pickup, their ride ends as cancelled by the driver, as today, and the rider gets a new ride request in the list. The new request has the same rider, pickup, drop-off, and fare, and keeps the original request time, so the wait time stays honest. A ride cancelled during the trip is over and doesn't return to the list.

Tests:
- Cancelling while heading to pickup, and at pickup, each adds a request for the same rider, places, and fare to the list, with the original request time and a new ID.
- The driver's past rides still show the cancelled ride as cancelled by the driver.
- Cancelling during the trip adds nothing to the list.

### The demo list changes over time

The demo starts with a few riders that other drivers have already passed on, each waiting several minutes. While the driver is online, another driver passes on a new request now and then, which adds it to the list without it being offered to this driver, up to a limit. One descriptively named rider shows the conflict case: another driver takes their ride just as this driver tries to.

Tests:
- The service starts with the seeded rides in the list, each with a past request time.
- A passed-over request arrives after the configured interval, and none arrive beyond the limit.
- Claiming the named rider's ride fails as taken by another driver, and the ride leaves the list.
- The seeded riders are their own, so none of them is also offered.
- A rider who already has a ride waiting or in progress isn't offered again, and isn't passed over again. If every repeating rider is waiting, no offer is made, and the offer timer tries again later.

### The driver can see the list

From the home screen, the driver opens a "Waiting Riders" screen. Each row shows the pickup, the drop-off, the fare, and how long the rider has waited, and the wait time keeps counting up while the screen is open. The list updates as the service reports changes. With no one waiting, the screen says so.

Tests:
- The wait time reads as a duration, such as "Waiting 4 min", for a range of waits, including under a minute.
- Checked in the simulator: the screen opens from home, rows show pickup, drop-off, fare, and wait time, the list changes as rides arrive and leave, and the empty state shows with no one waiting. No UI tests are added. The user runs the app to check.

### An offer opened from the list returns to it

An offer that arrives while the driver is on Waiting Riders, or any pushed screen, shows as a bar. Opening it shows the offer full screen, as before. If the offer then ends without a ride starting, declined, expired, or withdrawn, the driver is back on the screens they left. Accepting starts the ride, which stays the root screen.

Tests:
- No unit test: the saved screens are navigation state held in `RootView`. Checked in the simulator: open an offer from the bar on Waiting Riders, decline it, and see Waiting Riders again; accept one and see the current ride screen.

### Cancelling a ride taken from the list returns to it

If the driver took a ride from Waiting Riders and cancels it before the trip starts, they're back on Waiting Riders, where they were choosing rides. A completed ride, a ride cancelled during the trip, and a ride the rider cancelled all end on the home screen, as before.

Tests:
- No unit test: this is navigation state held in `RootView`. Checked in the simulator: take a ride from the list and cancel it at pickup, and see Waiting Riders; take one and complete it, and see the home screen.

### The driver can take a ride from the list

Each row has a button to take the ride, enabled only while the driver is available. Taking a ride starts it, and the driver sees the same current ride screen as after accepting an offer. If an offer is pending, taking a ride from the list declines it, and the offered ride joins the list.

Tests:
- Taking a waiting ride makes it the driver's active ride, sets the driver on a ride, removes it from the list, and schedules the rider's own cancellation, as accepting does.
- Taking a ride while offline, or while already on a ride, is refused, and nothing changes.
- Taking a ride that isn't in the list, such as the one being offered, fails with the new error, and the offer stays.
- Taking a ride while an offer is pending declines the offer, and the offered ride joins the list.
- The declined offer isn't reported to VoiceOver as one that ended unanswered.
- A forced network failure leaves the ride in the list and the driver available, and shows the error.
- A second tap during the request is ignored, as with every other action.

### A ride someone else took

If the ride was taken by another driver, or its rider cancelled, before the driver's request arrives, the request fails with a message that says so. The list the driver sees already reflects the change, because the same session removes the ride.

Tests:
- Taking a ride that another driver has taken fails with the new error, and nothing about the driver changes.
- Taking a ride whose rider has cancelled fails the same way.
- The model shows the new error's message, and the ride is gone from the model's list.
- A new offer, arriving during the request or after the message shows, doesn't hide the message. Other errors are still cleared by a new offer, as they could seem to describe it, but this one says the rider is no longer waiting.

## Out of scope

- Seeing other drivers, on a map or in a list. These moved to the README's future work in #10.
- Filtering or sorting the list beyond longest wait first.
- Distance from the driver to each pickup. The mock has no locations.
- Offering a ride from the list again.
- Offline behavior, including whether taking a ride can queue. #15 decides that.

## Decided

- Offers come first, and the list holds rides no driver took: declined, expired, or cancelled by the driver before the trip.
- A driver's cancellation before the trip gives the rider a new request in the list, with the original request time. A ride cancelled during the trip is over.
- The list is `waitingRides: [Ride]` on `DriverSession`, so one snapshot shows a taken ride leave the list and become active together, and the model can't show a ride as both.
- The service keeps the IDs of waiting rides that an offer didn't place, and the ride's status stays `awaitingDriver`. Being passed over is about dispatch, not the ride's lifecycle, so it stays out of the domain types.
- The list is a pushed "Waiting Riders" screen, opened from a toolbar button on the home screen beside Past Rides. The home screen stays focused on availability, and clearing the navigation path when a ride starts already covers a ride taken from a pushed screen.
- The list shows while offline, with the take buttons disabled and a line that says to go online to take a ride, so a driver can decide whether it's worth going online.
- Names:
  - `DriverSession.waitingRides`, for the list.
  - `RideService.claimRide(rideID:)` and `DriverModel.claimRide(rideID:)`, for self-assigning. "Claim" reads differently from accepting an offer, which keeps the two paths distinct in the code.
  - `RideServiceError.rideNoLongerWaiting`, with the message "This rider is no longer waiting. Another driver may have taken the ride, or the rider cancelled."
  - `AppDestination.waitingRiders`, `WaitingRidersView`, and `WaitingRideRow`, for the screen.
  - "Take Ride", for the row's button.
  - `MockRideServiceConfiguration.passedOverInterval` and `maximumWaitingRides`, for how often another driver passes on a request and how many riders can wait.
  - Rider "Taylor Taken", for the conflict demo, in the style of Will Cancel.

These go in the decision log in docs/PLAN.md with the PR.
