# Plan for #<number>: <issue title>

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work.

## Phase 1: <name>

- [ ] Write failing tests: <tests from the spec>
- [ ] <Code that makes them pass>
- [ ] Verify: <how to confirm, such as the tests passing, a simulator check, or a mutation check>

## Phase 2: <name, for a phase that can't be unit tested>

- [ ] No unit test: <why, such as state held in a view>
- [ ] <Code>
- [ ] Verify: <how, such as a simulator check>

## Phase 3: <name>

- [ ] Write failing tests: <tests>
- [ ] <Code>
- [ ] Verify: <how>

## Before the PR

- [ ] Review with the relevant Swift skills, as listed in "Development flow" in docs/PLAN.md
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: status, decision log, assumptions, and any outdated sections
