---
title: Build package_item_comment table + Notes panel persistence
status: open
severity: medium
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-05
completed_date: null
verified_live: false
github_issue: null
---

## Summary
The Notes panel in Package Builder's right rail has nothing to read/write
to — no comment table exists in `schema.ts`. Flagged as a demo-blocking gap
in the original design handoff.

## Notes (2026-08-08)
Reconfirmed while rebuilding the panel's styling — it's still a static "Reply or
@mention…" composer with a "No comments yet" placeholder, no backend. Explicit ask from
Darin: when this gets built, the whole thing needs to be real user-created content, not
just a message string —
- Comments belong to a real user (author, not a free-text name) via the existing
  `users`/session identity, timestamped for real.
- `@mention` needs to actually resolve to a real user (likely someone with a
  `productionMembers`/`companyMembers` row on this production), not just accept
  arbitrary `@text`.
- Whatever table lands (`package_item_comment` per the title, or scoped to the whole
  package rather than one line item — worth deciding which before building) should
  support that mention as a real reference, not a substring in the body, so a
  mentioned user could eventually be notified (see T0046 — Notification Center).
