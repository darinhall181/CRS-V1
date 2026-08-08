---
title: Read the real session server-side — retire DEMO_USER_ID, then DEMO_PRODUCTION_ID
status: done
severity: high
type: task
component: www/src/lib/auth.ts, www/src/app/(app)/package-builder/actions.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: 2026-08-08
verified_live: true
github_issue: null
---

## Summary
**Done 2026-08-08.** `DEMO_USER_ID` fully retired. `DEMO_PRODUCTION_ID` retired as the
primary path — it's now a documented fallback only, used when a signed-in user has no
`production_members` row (or nobody's signed in). `www/src/lib/session.ts` added:
`getSession()` wraps `auth.api.getSession({ headers: await headers() })`, usable from
both Server Components and Server Actions. `queries.ts` gained
`getActiveProductionForUser(userId)` (production_members → productions, status=active,
most recently updated, limit 1).

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

## Progress
- [x] `getSession()` helper (server components + server actions)
- [x] `actions.ts` derives `addedBy` from session, rejects unauthenticated calls
- [x] `page.tsx` resolves production from `production_members`, `DEMO_PRODUCTION_ID` as
      documented fallback only
- [x] End-to-end verification with a second test user

## Verification
Add an item to the package while signed in as a second (non-Darin) test user; confirm the
`package_items.added_by` row carries that user's id via direct DB read-back.

**Verified 2026-08-08.** Created a real test user via Better Auth's sign-up API
(`t0013-test@altoscope.so`, id `6be540bb-fbe3-4197-bf07-b1f45b9a7299`), inserted a real
`production_members` row (`dp` role) for the Top Gun Maverick production. Confirmed:
- Signed out → `GET /package-builder` 307s to `/login?next=%2Fpackage-builder` (middleware
  still correct).
- Signed in as the test user (real session cookie, `/api/auth/get-session` confirms the
  session resolves to that user) → page renders "Top Gun Maverick" / "Camera Package",
  proving `getActiveProductionForUser` resolved the real membership row, not just a
  coincidental fallback match.
- Called `addPackageItem` through the live dev server (a temporary route handler, deleted
  immediately after use — a standalone `tsx` script hit a cold-connection TLS reset against
  this Neon compute that the running Next server didn't) with the test user's id: inserted
  row's `added_by` exactly matches the test user's id (`addedByMatches: true`). Row deleted
  after confirming — this was a verification write, not real demo data.
- Did **not** click through the actual button in a live browser (no browser tool available
  in this environment) — the mutation itself was exercised via the same `addPackageItem`
  function the server action calls, with the real session-derived id, not a hand-rolled
  substitute.

The test user + membership row were left in the DB (harmless, useful fixture for future
multi-user testing — e.g. T0006's remaining role views) rather than cleaned up; flag if you'd
rather they be removed.
