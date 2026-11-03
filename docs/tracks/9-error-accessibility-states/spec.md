# #9: Error, empty, and accessibility states

Issue: https://github.com/sbcooney/fareline/issues/9

## Goal

The required flow holds up for every driver and every situation: it explains each failure and offers a way forward, it works with VoiceOver and at any text size or iPhone size, and it never makes the driver act on something they didn't mean to.

## Behavior

### Offers reach the driver without pulling them away

An offer must never be missed, but it shouldn't throw away what the driver is looking at. Today, an offer replaces the home screen, and on a pushed screen the navigation path is cleared to show it (see the comment from #8 on the issue).

How offers appear is decided below.

Tests:
- Checked in the simulator: an offer arriving on the home screen shows the offer screen.
- Checked in the simulator: an offer arriving on Past Rides or a ride's details shows a banner with the rider, fare, and countdown, and leaves the driver where they are. Tapping the banner opens the offer.
- Checked in the simulator: the banner disappears when the offer ends.

### The driver is told when an offer arrives or ends

When an offer arrives, VoiceOver announces it with the rider and fare, and the phone gives haptic feedback. When an offer ends without the driver responding, VoiceOver announces that it ended.

Tests:
- The model reports when the pending offer ended without the driver responding, and not when they accepted or declined it.
- Checked on a device or in the simulator with Accessibility Inspector: the arrival and end announcements are read. Haptics need a device, so they're checked there if one is available, and otherwise listed as not verified.

### A tap can't land on a control that just appeared

Accept sits where Go Offline was, and Go Offline returns where Accept was. A tap meant for one must not trigger the other.

Tests:
- Checked in the simulator: Accept and Decline ignore taps for a short time after the offer appears, and show that they're not ready yet. Go Offline does the same after an offer ends.
- VoiceOver users aren't held back: the controls are announced as unavailable until ready, rather than silently doing nothing.

### One alert at a time, and the right one

The app has two alerts, errors and rider cancellations, which can be due at the same time. Only one shows at a time, and a newer, more useful explanation replaces an older one.

Tests:
- A rider cancellation replaces a pending error.
- An error that arrives while a cancellation is showing doesn't replace it, except that a "no longer available" error after a cancellation is dropped, as now.
- A step that fails after the driver dismissed the cancellation doesn't show a redundant "no longer available" error.
- A new offer clears an error alert, so "no longer available" doesn't seem to describe the new offer. A cancellation alert stays.
- Dismissing the alert clears it.

### Every failure has a message and a way forward

Each `RideServiceError` shows a message that says what happened and what to do. The control that failed stays enabled, so the driver can try again.

Tests:
- Every error has a non-empty message. (Parameterized over all cases.)
- After each kind of failed action (availability, accept, decline, each ride step), the control is enabled again and the state is unchanged.

### Every screen has a sensible empty or waiting state

Tests:
- Checked in the simulator: Connecting, Past Rides with no rides, and a past ride that isn't available each show a clear state, not a blank screen.

### VoiceOver labels on every control and the countdown

Every control has a label that says what it does. The countdown is read as time remaining, such as "Time left, 27 seconds", not as "0:27".

Tests:
- An automated accessibility audit passes on each screen: home, offer, current ride, Past Rides, and ride details. It checks for missing labels, clipped text, contrast, and hit areas.
- Checked with Accessibility Inspector: the countdown's spoken value.

### Large text, Reduce Motion, and every iPhone size

Every screen works from the smallest text size to the largest accessibility size, with nothing clipped or truncated. This includes the offer and ride titles, which truncate today. Any animation this issue adds, such as the banner, uses a fade when Reduce Motion is on. Every screen works on the smallest and largest iPhones and on both of iPhone Duo's displays.

Tests:
- The accessibility audit above, run at the largest text size.
- Checked in the simulator, at the default and largest text sizes, in light and dark mode: every screen on iPhone 17e, iPhone 18 Pro Max, and iPhone Duo's outer display.
- Checked by you: iPhone Duo's inner display, and folding while an offer is showing. The simulator needs Device Hub for this, which only a person can drive.

## Out of scope

- Localization into other languages. The app has no String Catalog yet.
- Offline behavior (#15).
- iPad, landscape, and Split View, which the app doesn't support.

## Decisions

Decided on 2026-11-03 and recorded in the decision log in docs/PLAN.md:

- The offer screen stays the home screen's content. Over pushed screens, `OfferBanner` shows the offer instead, and the navigation path is no longer cleared for offers.
- Accept, Decline, and Go Offline ignore taps for 0.75 seconds after they appear, and look disabled until then.
- An offer that ends without a response gets a VoiceOver announcement only.
- `DriverAlert`, with `error(RideServiceError)` and `riderCancelled(Ride)`, replaces `lastError` and `cancelledRide` as `DriverModel.alert`, presented with `alert(_:item:)`.
- No retry button in the error alert.
- A `FarelineUITests` target runs `performAccessibilityAudit()` on each screen.
- Truncated titles: check whether iOS 27's large titles can wrap, and otherwise use shorter titles at accessibility sizes.
