# #34: Offer screen's largest-text audit fails with unattributed contrast issues

Issue: https://github.com/sbcooney/fareline/issues/34

## Goal

`testOfferScreenAtTheLargestTextSize` passes every time on a settled simulator, for a reason that's understood, so the UI test suite is green again. Any exception left in the audit covers exactly the cause, and is explained.

## What's known

- The test fails on `main` with 8 contrast issues that have no element. The default-size offer audit passes.
- The test's exception, from #19, accepts exactly one such issue. #19 found that only removing the countdown row made it go away.
- One run, on an overloaded machine, attributed the failures to the "Pickup" and "Union Station" text instead.

## Hypothesis

At the largest text size, the offer's details don't fit above the Accept and Decline buttons. The buttons sit in a bar with a translucent `.bar` background, and the list scrolls behind it, so the audit measures text showing through the bar. This explains the Pickup and Union Station attribution, why removing the countdown row helped by moving every row up, and why the default size passes. It doesn't yet explain why most issues have no element.

## Behavior

### The cause is confirmed or ruled out first

Before changing the screen or the test, a temporary test records, at the largest text size, which elements sit behind the bar and each audit issue's element and frame, if any, with a screenshot.

Tests:
- The hypothesis holds if the issues go away when nothing is behind the bar: with the list scrolled to the top and the bar made opaque, or with the bar removed in a temporary build.
- The hypothesis fails if the issues remain with nothing behind the bar. Then the countdown row is checked again, as #19 did.

### The audit passes reliably

Depending on the decision below, the screen or the test changes so the audit passes.

Tests:
- `testOfferScreenAtTheLargestTextSize` passes 5 times in a row on a settled simulator.
- The rest of the UI suite still passes.

## Out of scope

- Other screens' audits, unless the same cause is found there.
- Redesigning the offer screen beyond what the fix needs.

## Decisions needed

- **How long to investigate.** Recommendation: one session of up to an hour of simulator runs. If the cause isn't clear by then, stop and decide from what's known, rather than keep running tests.
- **The fix, once the cause is known.** Options, depending on what's found:
  - **If the bar is the cause:** give the bar an opaque background, such as the `surfaceRaised` token, at accessibility text sizes. Text no longer shows through, and the screen reads more clearly at that size. Recommendation, if confirmed, because it fixes what the audit measures rather than hiding it.
  - **If the cause is the system's own translucent material, and an opaque bar looks wrong:** narrow the test's exception to issues measured under the bar, and record why.
  - **If the countdown row is still the cause:** look at the row's redraw. #19 already ruled out its styling, redrawing, and accessibility setup, so this would likely end in an exception that accepts these issues, explained in the test and the decision log.
