---
name: work-issue
description: Advances a tracked task or finding through its lifecycle — marks it in-progress when work starts (self-assigns the linked GitHub issue) and marks it done/fixed plus closes the issue when work is verified complete. Companion to file-issue, which only handles creation. Use when the user says they're starting work on a tracked task/issue, or that one is done/fixed/complete.
---

# Work Issue

Keeps `docs/tasks/*.md`, `docs/browser-findings/*.md`, and their linked GitHub issues in sync as work actually happens — starting and finishing, not just filing. `file-issue` creates the record; this advances it.

## Finding the right item

Given a task ID (`T0004`), an issue number (`#9`), or just a description, locate the matching file in `docs/tasks/` or `docs/browser-findings/` — grep titles/frontmatter if not given an exact ID. Read its `github_issue` field: if set, that's the linked issue to keep in sync; if `null`, there's nothing on GitHub for this one — only the local file changes.

## Starting work

1. Read the file's current `status`. If it's `blocked` or `wontfix`, confirm with the user before proceeding rather than silently overriding it.
2. Set `status: in-progress` in the frontmatter.
3. If `github_issue` is set, self-assign: `gh issue edit <number> --repo darinhall/Altoscope --add-assignee @me`
4. Confirm back: file path, and issue number if one was touched.

## Marking work done

**Critical rule, learned from a real mistake (see `docs/browser-findings/2026-08-05-catalog-drawer-transparent-background.md` and the history on issue #9): a fix being *implemented* and a fix being *verified* are not the same thing. Closing an issue is a claim that it's actually resolved — don't make that claim on the strength of a code change alone.**

1. Determine the right terminal status from the file's `type`: `type: bug` → `fixed`, `type: task` / `improvement` → `done`.
2. **For `type: bug` entries with a UI-visible symptom** — check whether the *fix itself* has actually been confirmed live (not the same thing as the finding's `verified_live` field, which describes whether the *original bug* was reproduced live when found — a separate, earlier fact). If the fix hasn't been checked in an actual running browser:
   - Leave `status: in-progress`, not `fixed`
   - Post a comment on the linked GitHub issue describing the fix and explicitly stating it's unverified — don't close it
   - Say so plainly to the user rather than reporting it as done
3. **For `type: task` / `improvement` entries** without a browser-visible symptom (backend/data work) — reasonable confirmation is enough to close: typecheck passes, a DB query confirms the expected state, tests pass, etc. Set `status: done`.
4. When actually closing on GitHub: comment first with a summary of what was done (reference the task file path), then `gh issue close <number> --repo darinhall/Altoscope`.

## What NOT to do

- Don't mark a bug `fixed` or close its GitHub issue on implementation alone when it has a UI-visible symptom — see the rule above
- Don't touch a GitHub issue that isn't actually linked (`github_issue: null`) — only sync what's real
- Don't invent a new label or assignee convention beyond self-assignment without asking first
- Don't silently move a `blocked`/`wontfix` item back to `in-progress` — confirm first
