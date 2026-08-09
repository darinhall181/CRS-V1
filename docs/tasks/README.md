# Tasks

Git-committed, durable backlog for this repo — the reference for what's done, in progress, and open. This replaces relying on any single conversation's in-context task list (Claude Code's ephemeral TaskCreate/TaskUpdate tool tasks aren't committed to the repo and don't survive across sessions the way these files do).

## Folders

- `incoming/` — everything actionable right now: `open`, `in-progress`, `blocked` (on an
  in-repo decision — another task, a design call), `wontfix`.
- `postponed/` — `blocked`, but on something outside any Claude Code session's reach:
  a manual step in an external console (DNS/registrar, a paid dashboard), waiting on a
  real-world event (closer to launch, a contract signed), or anything else no amount of
  repo work moves forward. Keeps `incoming/` to things a session picking up the backlog
  can actually pick up next, without losing the task or implying it's done.
- `finished/` — `done` tasks, moved here when they're completed and signed off (see below).

A task file lives in exactly one of the three at any time. **Move it with `git mv`** (not
a plain copy) so history follows the file. This split exists because multiple sessions
(including concurrent ones) write task files here, and "is this actually actionable" or
"is this actually done" needs to be answerable by which folder a file is in, not just by
opening it and checking frontmatter.

## Naming

`T<4-digit number>-<lowercase-kebab-slug>.md`, e.g. `T0001-design-token-audit.md`. Numbers are sequential and never reused, even if a task is abandoned — check the highest existing number across **both** folders before creating a new one.

## Format

Same frontmatter schema as `docs/browser-findings/` (see that folder's README) — `type: task` or `type: improvement` for entries here, as opposed to `type: bug` for findings. One shared template, two purposes: findings are investigation records ("what did we discover"), tasks are units of work ("what should get done").

```yaml
---
title: Short, specific title
status: open            # open | in-progress | done | blocked | wontfix
severity: medium         # low | medium | high — urgency/impact, not difficulty
type: task               # task | improvement | bug
component: path/to/relevant/area
found_by: claude-code    # claude-browser | claude-code | manual-qa
found_date: 2026-08-05
completed_date: null     # YYYY-MM-DD, filled in when status flips to done — see "Signing off" below
verified_live: false     # has the DONE state actually been confirmed working live, or just implemented?
github_issue: null       # fill in once/if promoted to a GitHub issue, e.g. #12
---
```

Body: `## Summary` (what and why), `## Progress` (checklist, see below), `## Notes` (context, decisions, links to related findings/tasks), and whatever else is relevant — acceptance criteria, sub-steps, etc. Don't force sections that don't apply.

## Progress checklist

Any task with more than one real step gets a `## Progress` section with a markdown checkbox per step:

```markdown
## Progress
- [x] Add getSession() helper
- [x] Wire actions.ts to derive addedBy from the session
- [ ] Wire page.tsx production resolution
- [ ] Verify end-to-end with a second test user
```

This is the answer to "how far did this actually get" when a task is picked back up mid-way, interrupted, or partially done before something else took priority — check the boxes, don't just narrate progress in prose. A task with a single atomic step (e.g. a one-line config flip) doesn't need this section; use judgment.

## Signing off

When a task's status flips to `done`:
1. Set `completed_date` in frontmatter to the date it was actually finished (not `found_date`).
2. Check off every remaining box in `## Progress`.
3. Add a short dated note at the top of `## Summary` — e.g. `**Done 2026-08-08:** ...` — stating what actually shipped and any caveat (verified live vs. implemented-but-unverified, what was deferred, etc.). This is the human-readable version of the same fact `completed_date` encodes structurally.
4. `git mv` the file from `incoming/` to `finished/` in the same commit as the work it describes, where practical.

A task that's mostly done but has one deferred piece stays in `incoming/` with an accurate checklist — don't move it to `finished/` and caveat your way around an unchecked box.

## When to promote to a GitHub issue

Not every task needs one — GitHub issues are for anything that benefits from external visibility, cross-referencing a PR, or collaborative discussion. Use the `file-issue` skill (`.claude/skills/file-issue/`) to file it, then fill in the `github_issue` field here so the two stay linked instead of drifting into duplicates.
