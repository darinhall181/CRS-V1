---
title: Re-enable the auth middleware gate
status: done
severity: medium
type: task
component: www/src/middleware.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: 2026-08-08
verified_live: true
github_issue: null
---

## Summary
Batch 0 (Foundations), 2 of 5. Closes the loop on T0012: restore the working implementation
on `middleware.ts` (`getSessionCookie` from `better-auth/cookies`, redirect
to `/login?next=…` when absent).

**Done 2026-08-08** (parallel session, before this plan's task list existed — see T0012's
own log). Note: the comment claiming a working version was preserved in git history on this
file was inaccurate; it was written and short-circuited in the same commit, so it had to be
rebuilt from the spec left in that comment rather than restored.

Matcher currently only covers the three existing `(app)` routes
(`/package-builder`, `/gear`, `/compatibility-checker`) — **still open**: extend the matcher
as this plan's new routes (storefront/gear, map, profile, rfq) land.

## Verification
Signed-out request to /package-builder redirects to /login and returns to the original
page after sign-in (the `next` param round-trip) — verified against a running dev server
(curl, all three matcher routes 307 → /login; / and /login pass through). Browser-based
verification of the full sign-in round-trip still recommended before relying on this in
front of real user flows.
