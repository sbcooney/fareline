# Fareline

A rideshare driver app in SwiftUI, built as a take-home. The project plan, decisions, and development flow are in [docs/PLAN.md](docs/PLAN.md).

## Starting an issue

Run `/start-issue <number>` to write the issue's spec and plan in `docs/tracks/` before any code. Then work through the plan, checking off tasks as they're done.

## Lessons learned

A mistake an agent makes twice becomes a rule here, with the reason, so it isn't made a third time. Earlier rules that the user gave directly are included too.

- **Propose names and new types before creating them.** This includes structure added during cleanup. Why: the person who submits this code must be able to explain all of it, and a `CurrentScreenView` added during a cleanup without asking was a surprise.
- **Add no unused code.** Add a conformance, annotation, or capture list only when the code uses or requires it. Why: every line must be justifiable, and unused `Hashable` and `@ObservationIgnored` crept in out of habit. Exceptions: types with an identity are `Identifiable`, and the root `NavigationStack` with `AppDestination` is deliberate structure.
- **Update docs/PLAN.md in the same PR** as any work that completes an issue or changes a decision. Why: reviewers may read the plan, so it must stay accurate.
- **Fill in the PR template** in `.github/pull_request_template.md`, including the Swift skill reviews section. Why: the #27 description used its own format and dropped that section.
- **Don't merge PRs.** The user reviews and merges each one.
- **Report results as they are.** Say which checks ran and which didn't. Confirm a test fails without the code it covers before relying on it.
