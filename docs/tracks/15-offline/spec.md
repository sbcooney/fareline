# #15: Offline capability

Issue: https://github.com/sbcooney/fareline/issues/15

## Goal

When the connection drops, the driver can still see their current ride and history, and keep moving their own ride forward. Their steps are sent in order when the connection returns. Anything that needs a live answer, such as accepting an offer, says it needs a connection rather than failing.

The assignment asks only for "offline capability in case of loss of connectivity", and warns against over-engineering. This track keeps to what makes the app useful offline, and documents the rest as simplifying assumptions.

## Background

The mock service is the app's stand-in for a backend, and it runs inside the app. Being offline is simulated between the model and the mock: requests fail and updates don't arrive, while the mock's own world keeps running, so offers expire and riders cancel as they would on a real server.

## Behavior

### Connectivity can be simulated, and the driver can tell they're offline

The mock can be told the connection is lost or back. While it's lost, every request fails with `networkUnavailable` and changes nothing, and the session stream sends nothing. When the connection returns, the stream sends the latest session. A demo control turns it on and off.

While offline, a banner below each screen's navigation bar says there's no connection, and how many ride steps are waiting to be sent, if any. It says "no connection" rather than "offline", which the app already uses for a driver who isn't taking rides. The ride and offer screens show their title small in the bar while offline, as the banner sits where a large title would. VoiceOver announces "Connection lost" and "Connection restored".

Tests:
- While disconnected, each request fails with `networkUnavailable`, and the mock's state is unchanged.
- While disconnected, the stream sends nothing, and on reconnecting it sends the latest session, including changes made meanwhile, such as an expired offer.
- The banner's text with no steps waiting, one, and several.
- Checked in the simulator: the banner appears and disappears with the demo control, and VoiceOver announces each change.

### The current ride and history stay available

Offline, the driver still sees their current ride, past rides, and the waiting list as last received. Actions that need a live answer are disabled, with a line saying they need a connection: going online or offline, accepting or declining an offer, and taking a ride from the list.

Tests:
- Actions that need a connection are refused while offline, without sending a request.
- Checked in the simulator: the current ride, Past Rides, and Waiting Riders all show offline, and the disabled controls explain why.

### The driver's own ride steps queue, and replay in order

Offline, I've Arrived, Start Trip, Complete Trip, and Cancel Ride still work on the driver's current ride. Each is applied to the ride on screen straight away, so the driver can keep going, and queued. When the connection returns, the queue is sent in order, one request at a time.

If the service rejects a queued step, the server wins: the rest of the queue is dropped, the model shows the service's session, and the driver is told their offline steps couldn't all be sent. If the rider cancelled while the driver was offline, the existing rider-cancelled alert explains it instead.

Tests:
- A step taken offline updates the ride on screen and queues, without sending a request.
- Several steps queue in order, and replay in that order on reconnecting.
- A step that isn't allowed from the ride's status on screen is refused, as online.
- After a successful replay, the queue is empty and the model shows the service's session.
- A rejected step drops the rest of the queue, shows the service's session, and tells the driver.
- A rider's cancellation while offline shows the rider-cancelled alert, not the conflict message.
- A network failure during replay keeps the queue, to retry on the next reconnect.

## Out of scope, documented as simplifying assumptions in the README

- Surviving a relaunch while offline. The mock "server" restarts with the app and saves only past rides, so this would need the app and the mock to save their whole state.
- Real network monitoring with `NWPathMonitor`. A real app would use it to set the same offline state the demo control sets.
- Queuing actions that need a live answer.
- Handling each kind of conflict differently. The server's session always wins.

## Decided

- The driver's own ride steps queue offline: I've Arrived, Start Trip, Complete Trip, and Cancel Ride, after its usual confirmation. A driver may need to end an unsafe trip without signal. Everything else needs a live answer and is disabled offline.
- Each queued step is applied to the ride on screen straight away, using the domain's own transition rules, so the driver can keep going. In exchange, the model holds a little logic of its own.
- `completeTrip` and `cancelRide` take the time of the tap, so a trip completed offline keeps its real end time. Online calls pass the current time.
- Being offline is never polled for. The service reports changes through a stream, which a real app would feed from `NWPathMonitor`, and the mock feeds from its switch.
- A Demo menu in the main screen's toolbar, in Debug builds only, turns it on and off, and the README explains it. It shows on every main screen, home, an offer, or the current ride, so the connection can be lost mid-ride, and its item reads "Simulate No Connection" or "Restore Connection" from the model's state. There's no `-offline` launch argument: no UI tests are added, so it would be unused.
- Names:
  - `RideService.connectionUpdates() -> AsyncStream<Bool>`, sending whether the connection is up, now and on each change.
  - `MockRideService.setConnected(_:)`, the mock's switch.
  - `completeTrip(rideID:at:)` and `cancelRide(rideID:at:)`.
  - `DriverModel.isOffline`, and `DriverModel.pendingSteps: [PendingRideStep]`, in order.
  - `PendingRideStep`, a ride ID and the domain's `RideEvent`.
  - `DriverAlert.offlineStepsNotSent`: "Some steps you took offline couldn't be sent. Your ride shows its latest state."
  - `OfflineBanner` and `DemoMenu`, with a Debug-only `demoService` environment value that gives the menu the mock.
  - A "Simulating no connection" section in the README.

These go in the decision log in docs/PLAN.md with the PR.
