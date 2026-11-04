# #17: Final submission

Issue: https://github.com/sbcooney/fareline/issues/17

## Goal

The repository is public, someone else can clone and run it from the README alone, and the link is sent. Before that, the accessibility audits cover both light and dark mode, and every document matches the final app.

## Behavior

### The audits run in light and dark mode

Each accessibility audit runs in both appearances, as it already runs at two text sizes. The test sets the simulator's appearance itself, through `XCUIDevice.shared.appearance`, and puts it back afterwards, so the result no longer depends on how the simulator was left.

Tests:
- Every audit passes in both modes.
- The Past Rides audit fails in light mode with #10's contrast fix reverted, which shows light mode is really checked.
- A test leaves the simulator in the appearance it found.

### The documents match the final app

The README, its screenshots, and `docs/PLAN.md` describe the app as it is. No issue is left unfinished, so nothing moves to future work. The README's test section says the audits run in both modes.

Tests:
- None: documentation. Verified by reading against the code, and by the clean-clone walkthrough.

### Nothing private is in the repository

No assignment PDF, secrets, absolute paths, or personal signing team is in the files or the git history. Your signing team, set for running on your phone, is reverted before the check.

Tests:
- A search of every commit for PDFs, keys, tokens, and `/Users/` paths, and of the project file for `DEVELOPMENT_TEAM`, finds nothing.

### Someone else can clone and run it

Xcode compiles every file in the project's folders, committed or not, so a file missing from git builds here and fails for anyone else. A fresh clone, in a new folder with no DerivedData, builds and passes its tests with the README's terminal command. Once the repository is public, it's visible to someone who isn't signed in, and the README renders.

Tests:
- The fresh clone's build and tests pass.
- You open the public link in a private browser window. Optionally, you open the fresh clone in Xcode and run it with no signing team selected.

## Out of scope

- New features or redesigns. Anything found during the check that isn't a bug goes to the README's future work.

## Decisions

Decided with the user on 2026-11-04:

- Each audit test loops over light and dark, as it loops over text sizes. The shared `launch` sets the appearance, and `tearDown` restores the one the test found.
- No recording. The screenshots meet the assignment.
- Claude makes the repository public only when you say so at that moment, and you send the link yourself.
- The clean-clone check is shortened to what catches real problems: Claude clones into a new folder and builds and tests from the terminal, and searches for private details. You open the public link in a private browser window, and optionally run the clone in Xcode. Cloning without credentials, a full walkthrough, and a second person were dropped, as the private window and your earlier review cover them.
- You revert your signing team once you're done with your phone, before the search.
- One PR with the audit change and final documents, saying "Part of #17". The public steps follow it, and #17 closes last.
