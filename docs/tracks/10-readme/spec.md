# #10: README and visual reference

Issue: https://github.com/sbcooney/fareline/issues/10

## Goal

A reviewer can see what the app does before building it, build and try it from the README alone, and read the design reasoning the assignment asks for: architecture and state management, data storage, real trade-offs, simplifying assumptions, future work, and how AI tools were used.

## Behavior

### The README opens with what the app looks like

The "In development" line goes. Screenshots of the primary flow sit near the top: going online, an offer, the current ride, and past rides, each with alt text saying what it shows.

Tests:
- None: documentation. Verified by viewing the README on GitHub's renderer, in light and dark.

### A reviewer can try every feature from the README

A "Trying the app" section walks the primary flow, then the extended features: Waiting Riders and taking a ride, the demo riders Will Cancel and Taylor Taken, cancelling a ride, and the past rides filter. The existing "Simulating no connection" section joins it.

Tests:
- None: documentation. Verified by following every step in the simulator, on a fresh install.

### The design section answers the assignment's questions

A "Design" section covers:
- **Architecture and state management:** the layers diagram, the one app model with views asking it what the driver can do, versioned session snapshots, the actor mock, offline queuing, and why there are no per-screen view models.
- **Data storage:** past rides in a JSON file written by `PastRideStore`, owned by the mock as a backend's stand-in, rebuilt through the domain's rules when read. In production, the backend's database is the source of truth, with an on-device cache for offline use.
- **Trade-offs:** a few real ones, each saying what was given up, with a link to the decision log for the rest.
- **Simplifying assumptions:** the list from `docs/PLAN.md`, written for a reader.
- The existing design system and Rider Companion sections move under it.

Tests:
- None: documentation. Every type, method, and file the README names is checked against the code.

### Future work includes the features left out

"What I'd change or add with more time" gains a map of other drivers (#11), a list of other drivers and their statuses (#14), and status outside the app (#23), each saying the idea, why it matters, and why it wasn't built. It also covers app-level gaps, such as a real network layer and surviving a relaunch offline.

Tests:
- None: documentation.

### The String Catalog matches what Xcode writes

Building in Xcode re-sorted the catalog and dropped the Demo menu's titles and a preview's placeholder text, for a reason that wasn't found: a device build still extracts them. That text is now marked as not for translation, so no build adds or removes it, and the catalog is committed in Xcode's order. The plan's claim that building doesn't change it is corrected.

Tests:
- The message tests still pass, as their plural entries are unchanged.

### Section text passes contrast in light mode

Running the UI tests with the simulator in light mode, left that way by the screenshots, showed Past Rides' count header falling short of contrast. It and Waiting Riders' footer used the system's gray rather than `textSecondary`.

Tests:
- The Past Rides accessibility audit fails in light mode before the fix and passes after. Every UI test passes in both modes.

## Out of scope

- The clean-clone check, making the repository public, and submitting, which are #17. #17 also makes the audits run in both modes.
- App code beyond the String Catalog fix and the contrast fix above.

## Decisions

Decided with the user on 2026-11-04, and recorded in the decision log:

- Four light mode screenshots of the primary flow, on an iPhone 18 Pro, in `docs/images/`, then one in dark mode.
- Captured by a temporary UI test, deleted afterwards. #17 runs it again if the screens change.
- Featured trade-offs: one app model rather than a view model per screen, complete versioned snapshots, one app target rather than a shared package, and an offer as the whole home screen.
- The past rides filter is left out of future work, as #33 built it.
- The README's order: intro and screenshots, requirements, build and run, trying the app, tests, lint, and design. Future work and AI tools sit inside the design section, as the assignment lists them as part of it. The AI note stays detailed rather than short.
- Debug-only and preview text is marked as not for translation, so building doesn't change the String Catalog.
