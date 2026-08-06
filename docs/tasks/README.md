# Tasks

Git-committed, durable backlog for this repo — the reference for what's done, in progress, and open. This replaces relying on any single conversation's in-context task list (Claude Code's ephemeral TaskCreate/TaskUpdate tool tasks aren't committed to the repo and don't survive across sessions the way these files do).

## Naming

`T<4-digit number>-<lowercase-kebab-slug>.md`, e.g. `T0001-design-token-audit.md`. Numbers are sequential and never reused, even if a task is abandoned — check the highest existing number before creating a new one.

## Format

Same frontmatter schema as `docs/browser-findings/` (see that folder's README) — `type: task` or `type: improvement` for entries here, as opposed to `type: bug` for findings. One shared template, two folders by purpose: findings are investigation records ("what did we discover"), tasks are units of work ("what should get done").

```yaml
---
title: Short, specific title
status: open            # open | in-progress | done | blocked | wontfix
severity: medium         # low | medium | high — urgency/impact, not difficulty
type: task               # task | improvement | bug
component: path/to/relevant/area
found_by: claude-code    # claude-browser | claude-code | manual-qa
found_date: 2026-08-05
verified_live: false     # has the DONE state actually been confirmed working live, or just implemented?
github_issue: null       # fill in once/if promoted to a GitHub issue, e.g. #12
---
```

Body: `## Summary` (what and why), `## Notes` (context, decisions, links to related findings/tasks), and whatever else is relevant — acceptance criteria, sub-steps, etc. Don't force sections that don't apply.

## When to promote to a GitHub issue

Not every task needs one — GitHub issues are for anything that benefits from external visibility, cross-referencing a PR, or collaborative discussion. Use the `file-issue` skill (`.claude/skills/file-issue/`) to file it, then fill in the `github_issue` field here so the two stay linked instead of drifting into duplicates.
