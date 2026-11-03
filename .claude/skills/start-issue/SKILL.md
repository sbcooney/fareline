---
name: start-issue
description: Start work on a GitHub issue by writing its track, a spec and a plan in docs/tracks, before any code. Use when the user runs /start-issue <number> or asks to start an issue.
---

# Start an issue

Writes the track for one issue: `docs/tracks/<number>-<slug>/spec.md` and `plan.md`. No code is written until the user has reviewed both.

## Steps

1. **Read the issue.** Run `gh issue view <number> --json number,state,title,body,labels,comments`. Stop and tell the user if the issue is closed or doesn't exist.
2. **Read the context.** Read `docs/PLAN.md` (open questions, assumptions, and the decision log entries that mention this issue), `CLAUDE.md`, and the code the issue touches. Don't plan against code you haven't read.
3. **Choose the folder.** The folder is `<number>-<slug>`, where the slug is two to four lowercase, hyphenated words from the title. For example, issue 8, "Review past rides", becomes `docs/tracks/8-past-rides/`. If the folder already exists, stop and ask whether to replace it.
4. **Write `spec.md`** from [spec-template.md](spec-template.md). Describe behavior the driver or a caller can observe, not implementation. Every scope item in the issue maps to at least one behavior, and every behavior lists the test cases that prove it, including failure and edge cases.
5. **Write `plan.md`** from [plan-template.md](plan-template.md). Break the work into phases that each leave the app building. Each phase lists its failing tests first, then the code that makes them pass, then a verify step. If a phase's behavior can't be unit tested, such as state held in a view, say so in the phase and verify it another way. Pick the Swift skills from the table in "Development flow" in `docs/PLAN.md`, and name each one, with the files it covers, in the plan's "Before starting" and "Before the PR" sections.
6. **List decisions for the user.** Open questions, new type names, and structural changes go in the spec's "Decisions needed" section. Don't decide them in the plan.
7. **Stop.** Show the user the folder path, a short summary of each file, and the decisions needed. Wait for their review before writing code.

## While working on the issue

- Check off plan tasks as they're done, in the same commits as the work.
- If the work changes the expected behavior, update `spec.md` first, then the tests.
- When the PR opens, its description links the track folder with a full GitHub URL, because relative links in a PR description don't resolve to the repository.
