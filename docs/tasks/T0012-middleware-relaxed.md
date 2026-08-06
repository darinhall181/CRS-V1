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
security payoff. The working redirect implementation (session-cookie check,
`/login` redirect) is preserved in git history on this file, not deleted.

## Notes
Re-enable when starting T0007 (role-based UI gating) / T0006 (real role
views) — that's when the gate starts protecting something real.
