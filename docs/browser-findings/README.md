# Browser Findings

Investigation records for bugs and issues found while actually driving the app in a browser (interactive Claude Code session with the browser extension, or manual QA) — captured with enough technical detail (how it was found, root cause, suggested fix) to be useful to whoever picks it up next, even in a completely fresh session.

## Naming

`<YYYY-MM-DD>-<lowercase-kebab-slug>.md`, dated by when it was found.

## Format

Same frontmatter schema as `docs/tasks/` (see that folder's README) — `type: bug` for entries here.

```yaml
---
title: Short, specific title
status: open            # open | in-progress | fixed | wontfix
severity: high           # low | medium | high
type: bug                # bug | task | improvement
component: path/to/file.tsx
found_by: claude-browser  # claude-browser | claude-code | manual-qa
found_date: 2026-08-05
verified_live: true      # was this actually reproduced live, or inferred from code reading?
github_issue: null       # fill in once filed, e.g. #9
---
```

Body sections: `## Summary`, `## How it was found`, `## Root cause`, `## Suggested fix`, `## Repro steps`. Omit whichever don't apply rather than filling them with placeholders — a finding with an unconfirmed root cause should say so, not guess.

## Relationship to GitHub issues

This folder is the capture layer — the rich technical record, written right after live investigation while the detail is fresh. GitHub issues (via the `file-issue` skill) are the tracking/visibility layer. A finding gets promoted to an issue once it's actionable; fill in `github_issue` here once filed so the two don't drift into duplicates. Don't file a new issue for a finding that already references one — comment on the existing issue instead.

**Be honest about `verified_live` and `status` at every stage — including after a fix is applied.** A fix being *implemented* isn't the same as it being *verified working live*. If you can't check it live yourself (no browser access), say so and leave `status: in-progress`, not `fixed`.
