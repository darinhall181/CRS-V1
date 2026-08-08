---
title: Read the real session server-side — retire DEMO_USER_ID, then DEMO_PRODUCTION_ID
status: open
severity: high
type: task
component: www/src/lib/auth.ts, www/src/app/(app)/package-builder/actions.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 0 (Foundations), 1 of 5. Every screen after this needs "who is the viewer" answered
for real. Two shims exist: `DEMO_USER_ID` in `package-builder/actions.ts` and
`DEMO_PRODUCTION_ID` in `package-builder/page.tsx`.

- Add a `getSession()` helper (Better Auth `auth.api.getSession({ headers })`) usable in
  server components and server actions.
- `actions.ts`: derive `addedBy` from the session; reject unauthenticated mutation calls.
- `page.tsx`: resolve the production from the user's memberships
  (`production_members` → most recent active production) with `DEMO_PRODUCTION_ID` as
  fallback only while there is exactly one seeded production. Leave a `TODO(T00xx)` for
  real production selection/routing — still a separate, bigger feature.

~~Also settle the authoritative migration path here.~~ **Decided 2026-08-08** (Darin):
the DB is Neon; `schema.ts` + `drizzle-kit generate` are authoritative, `supabase/`
is historical. CLAUDE.md updated the same day. What remains for this task on that front:
one `db:studio` diff of schema.ts vs the live Neon branch before the first new-table
migration (T0023), since branch drift exists across the repo.

## Verification
Add an item to the package while signed in as a second (non-Darin) test user; confirm the
`package_items.added_by` row carries that user's id via direct DB read-back.
