---
title: Persist Package Builder line items to package_items (not just in-memory state)
status: done
severity: high
type: task
component: www/src/app/(app)/package-builder/
found_by: claude-code
found_date: 2026-08-05
completed_date: 2026-08-05
verified_live: false
github_issue: null
---

## Summary
`PackageBuilderClient` holds line items in React state only — nothing
writes to the real `package_items` table. Need
`addPackageItem`/`updatePackageItemStatus`/`removePackageItem` query
functions plus wiring so changes survive a page refresh.

## Done
- `getPackageItems`, `addPackageItem`, `removePackageItem` added to
  `lib/db/queries.ts`
- `page.tsx` now reads real `package_items` rows via `getPackageItems`
  instead of fabricating an in-memory seed — the in-memory `seedGear`
  logic is gone entirely
- `actions.ts` (new, `"use server"`) wraps the add/remove queries for the
  client component to call, with `revalidatePath`
- `package-builder-client.tsx`: `addToPackage` and `removeBulkSelected`
  are now async — optimistic UI update first (temp id for adds), then the
  real server call; on add success the temp id is swapped for the real DB
  id so a subsequent remove targets a valid row; on add failure the
  optimistic row is rolled back
- **Verified two ways, not just typechecked:** (1) rendered HTML confirms
  all 4 real seeded items load from the DB on page load; (2) called
  `addPackageItem`/`removePackageItem` directly against the real database
  in isolation (bypassing the Server Action transport) — row count went
  4→5→4 exactly, confirming the actual persistence logic works, not just
  that it compiles

## Notes
`updatePackageItemStatus` was scoped in the original ask but not built —
there's no UI action that changes a line item's status yet (no button
wired to it), so building the query function now would be speculative.
Add it when a real status-changing interaction exists.

No `qty` editor UI exists yet either — quantities are fixed at what was
seeded. Same reasoning: build the mutation when there's a real UI trigger
for it, not before.

`addedBy` on every write is hardcoded to Darin's user id (`DEMO_USER_ID`
in `actions.ts`) — same shim pattern as `DEMO_PRODUCTION_ID`, real
attribution needs T0007 (session reading).
