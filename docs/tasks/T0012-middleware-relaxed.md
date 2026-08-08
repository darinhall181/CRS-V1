---
title: Auth middleware temporarily disabled — re-enable before role-gating work
status: done
severity: low
type: task
component: www/src/middleware.ts
found_by: claude-code
found_date: 2026-08-05
verified_live: true
github_issue: null
---

## Summary
Decided 2026-08-05: relaxed `middleware.ts` to always allow through, since
no page differentiates by role yet and all data is synthetic — the
login-gate was pure friction during active UI iteration with no real
security payoff.

**2026-08-08: re-enabled.** Session-cookie check via `getSessionCookie`
(`better-auth/cookies`), redirect to `/login?next=<path>` when absent,
matcher on `/package-builder`, `/gear`, `/compatibility-checker`. Verified
against a running dev server — all three gated routes 307 to `/login`,
`/` and `/login` pass through. Note: the original comment claiming the
working version was "preserved in git history" was inaccurate — it was
written and short-circuited in the same commit (`ec0d2a6`), so it had to
be rebuilt from the spec left in that comment, not restored.

## Notes
This only re-adds session gating (logged-in or not) — role-based gating
still needs T0006 (real role views) before T0007 has anything to gate on.
