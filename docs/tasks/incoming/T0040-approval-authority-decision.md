---
title: Approval authority — who can flip packageItems.status to approved
status: blocked
severity: high
type: task
component: www/src/lib/db/queries.ts, www/src/lib/session.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
From the 2026-08-08 workshop, section 3 — flagged as an open decision, not yet made.
Schema already has `packageItems.approvedBy` and an `approved` status; what's missing is
a rule for *who* is allowed to set it. Two candidate rules, which give **different
answers** for the same user in some cases (e.g. a DP who also owns the company) — this is
exactly why it needs an explicit decision, not a default-by-whichever-field-is-populated:

1. Tied to `companyMembers.role` — owner/admin can approve.
2. Tied to `productionMembers.role` — producer/coordinator can approve, DP/gaffer cannot.

Broader permissions framing from the same workshop, for context when this gets decided:
confirmed **not** to fork the UI between rental house / production studio / hobbyist /
role types — one shared experience. The only two things that actually differ across
users are (a) company context — studio members need a company switcher, solo users don't
— and (b) this approval-authority gate. Everything else (role labels like DP/gaffer/DIT)
is bio/profile metadata for discovery, not a reason to build separate views.

## Blocked on
An explicit decision from Darin on which rule (or combination) governs approval. Directly
relevant to **T0017** (`getViewerContext()`) — that helper's role resolution should be
designed with whichever answer this task settles on in mind, so flag this as a
pre-read before implementing T0017's approval-relevant logic, even though T0017 doesn't
need to be blocked on this to build session/role resolution generally.

## Notes
Company-switcher UI (the other differentiator this workshop confirmed) is in scope for
T0016 (app shell/global nav) — studio members need it, solo users don't, but it's still
one shared app shell component, not a fork.
