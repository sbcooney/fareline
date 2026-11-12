# #46: Let the driver get help at pickup

Issue: https://github.com/sbcooney/fareline/issues/46

## Goal

A driver waiting at pickup can call the rider or Fareline support, or cancel, from one Get Help button under Start Trip. Today the only option when a rider doesn't come out is to cancel.

## Behavior

### Get Help appears only at pickup

At pickup, a Get Help button sits under Start Trip and opens a Help sheet of its own. It doesn't appear while heading to pickup or on trip. Like the Ride Options button, it's disabled while a request is in progress, because the sheet holds Cancel Ride. The Ride Options button and its sheet don't change.

Tests:
- No unit test, because the rule is a status check in the view. Screenshots show the pickup screen with the button, and the en route and on trip screens without it.

### The Help sheet

The Help sheet lists Call Rider, Contact Fareline Support, and Cancel Ride, in that order. Call Rider and Contact Support open a `tel:` link, so iOS asks the driver to confirm before it calls. On a device that can't make calls, such as the Simulator, an alert says so and shows the number, rather than the tap silently doing nothing. Cancel Ride asks for the same confirmation as in Ride Options, and either answer closes the sheet.

Tests:
- No unit test for the calls, which are view wiring, or for the confirmation, which `RideStatus.cancellationMessage` tests already cover. Screenshots show the sheet at the default and largest text sizes. In the Simulator, each call shows the alert with its number.

### Every rider has a fake phone number

`Rider` has an optional phone number. Every mock rider has a different number in the 555-0100 to 555-0199 range, which is reserved for fiction. The support number is in the same range.

Tests:
- Every mock template's rider has a phone number of the form `202-555-01xx`.
- The mock riders' numbers are all different.

### Saved history still loads

Past rides saved before this issue have no phone number and still load, with no number.

Tests:
- A ride with a phone number round-trips through `Codable` with the number.
- A ride saved without a phone number decodes with `nil`.

## Out of scope

- Changes to the Ride Options button or sheet.
- Calling from Past Rides.
- Messaging the rider or support in the app.
- Masking the rider's number through a proxy, as real rideshare apps do. Noted in the README's "What I'd do with more time".
- Get Help while heading to pickup or on trip.

## Decided

Recorded in the decision log in docs/PLAN.md on 2026-11-12. Details that don't need a log entry:

- **Names:** `RideHelpSheet`, titled "Help", opened by a "Get Help" button, and `Rider.phoneNumber`. Get Help is a few lines in `CurrentRideView`'s bottom inset, holding the sheet's `@State`, with no button type of its own.
- **Support number:** `202-555-0100`, a private constant in `RideHelpSheet`, its only user.
- **Get Help's style:** a full-width bordered button under the filled Start Trip, so that it's clearly secondary.
- **Call Rider without a number:** it doesn't appear. Only rides saved before this issue lack a number.
- **Accessibility audit at pickup:** the current ride audit stops en route, so it doesn't see Get Help. UI tests aren't changed. The screenshots and Accessibility Inspector check the pickup screen and the sheet instead.
