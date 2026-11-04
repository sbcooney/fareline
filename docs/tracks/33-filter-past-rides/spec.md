# #33: Filter past rides

Issue: https://github.com/sbcooney/fareline/issues/33

## Goal

A driver with a long history sees the rides they were paid for first, and can choose to see cancelled rides, or every ride, when they need to.

## Behavior

### The driver can choose which past rides to show

Past Rides has a filter in its toolbar with All Rides, Completed, and Cancelled. The screen always opens on Completed, so cancelled rides are hidden until the driver chooses otherwise. Completed shows rides that finished with a fare. Cancelled shows rides cancelled by either party, and each row still says who cancelled. The list keeps its order, newest first. The choice lasts while the driver views a ride's details and comes back, and resets to Completed when Past Rides is opened again. The toolbar control looks different while a filter other than All Rides is on, so a sighted driver can tell the list is filtered.

Tests:
- Each filter matches the right rides: All Rides matches every ride, Completed matches only completed rides, and Cancelled matches rides cancelled by the rider and by the driver.
- Filtering keeps the rides' order.
- Each filter's title, for the menu.
- Checked in the simulator: Past Rides opens on Completed; a choice survives viewing a ride's details; leaving Past Rides and opening it again shows Completed.

### A filter that matches nothing says so

When rides exist but none match the filter, the screen says there are no rides of that kind, and offers a button to show all rides. This is separate from having no past rides at all, which keeps the current empty state.

Tests:
- The empty state's title for Completed and for Cancelled.
- Checked in the simulator: with only cancelled rides, Past Rides opens on the Completed empty state, and its button shows all rides.

### The driver knows how many rides are showing

While a filter other than All Rides is on, the list's header says how many rides match out of the total, such as "3 of 8 rides". Changing the filter tells VoiceOver what's showing now, such as "Showing 3 completed rides".

Tests:
- The header text, with singular and plural counts.
- The VoiceOver announcement for each filter, with singular and plural counts, including All Rides.
- Checked in the simulator with VoiceOver: changing the filter announces the new count.

## Out of scope

- Filtering by date, fare, or place.
- Searching past rides.
- Remembering the filter after leaving Past Rides, or between launches.

## Decided

- The screen opens on Completed, so cancelled rides are hidden by default. The header's count shows that some rides are filtered out.
- Cancelled is one choice, not split by who cancelled, because each row already says "Cancelled by You" or "Cancelled by Rider".
- The filter is the screen's own state. It survives viewing a ride's details, and resets to Completed each time Past Rides opens, so the screen always opens the same way.
- A filtered list shows a section header such as "3 of 8 rides". With All Rides, there's no header, as today.
- Names:
  - `PastRideFilter`, an enum with `all`, `completed`, and `cancelled`, in `Features/PastRides`. It holds the matching rule and the text for the menu, the empty state, the header, and the announcement, so they can be unit tested.
  - `PastRideFilterTests`, for its tests.
  - "Filter", for the toolbar control's label, with the menu's choices titled "All Rides", "Completed", and "Cancelled".
- #33 on GitHub no longer says it's future work, and its scope says the filter opens on Completed.

These go in the decision log in docs/PLAN.md with the PR.
