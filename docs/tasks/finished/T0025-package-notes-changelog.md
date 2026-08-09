---
title: Package notes thread + change log (lands T0008)
status: done
severity: medium
type: task
component: www/src/lib/db/schema.ts, www/src/app/(app)/package-builder/
found_by: claude-code
found_date: 2026-08-08
completed_date: 2026-08-09
verified_live: true
github_issue: null
---

## Summary
**Done 2026-08-09:** `package_events` built and wired as Package Builder's History tab
(replacing the global nav placeholder — see below), and `package_comments` got its
edit/delete pass (soft-delete via `deleted_at`, "(edited)" indicator via `updated_at`).
Events are written directly from every real mutation (item add/qty-update/remove, comment
add) in the same DB transaction, then mirrored into client state so the tab updates
without a refetch. Verified live: added/edited/deleted a comment and an item, confirmed
each produced the right History entry with correct actor/timestamp/description.

Batch 3 (Package Builder), 2 of 3. Two small tables:

```
package_comment(id, package_id → packages, package_item_id → package_items nullable,
                author_id → users, body, created_at)
package_event(id, package_id, actor_id, kind, payload jsonb, created_at)
```

Comments power the Notes tab (avatar, name, timestamp, body, reply box — @mention render
can be plain text in v1). Events power the change log ("Coordinator added Ronin 2") —
written from the existing server actions (add/remove/status transitions), not
reconstructed after the fact. Attribution comes free from T0013.

## Notes
This supersedes/implements T0008 — close it pointing here. `package_event` is deliberately
generic: the RFQ timeline (T0031) will want the same shape scoped to a quote; decide at
T0031 whether to reuse this table with a quote_id column or mirror it — don't design for
both today.

**2026-08-08 update — T0008 landed the `package_comment` half already** (as
`package_comments`/`package_comment_mentions`, real user + real @mention references, see
`docs/tasks/finished/T0008-package-item-comments.md`). What's still open here is
specifically the `package_event` table/changelog — nothing else changes about this task's
scope.

**2026-08-09 — this is also where "History" belongs.** Discussed with Darin: the global
"History" nav item (was an inert placeholder in `nav-items.tsx`, part of T0016's 6-item
shell) doesn't reflect how history actually gets used — almost all of it is package-scoped
("what happened to *this* package"), not a cross-app destination. Decision, now built:
- Removed "History" from the global left nav entirely (`nav-items.tsx`).
- `package_event` now exists and is surfaced as a tab on Package Builder itself, alongside
  Detail/Budget/Notes — this is the "under the base of the packages page" Darin described,
  landing on the single-package view (package-builder) rather than T0047's packages *list*
  page, since a change log belongs to one package, not the list of them.
- A cross-package "recent activity" feed on Dashboard (T0043) is still just a plausible
  secondary surface later, not built — wasn't required for this task.

**2026-08-09 — `package_comments` edit/delete, built.** Darin flagged the Notes panel
needed real edit/delete, not just post-only:
- **Soft-delete**, not hard `DELETE` — nullable `deleted_at` on `package_comments`,
  filtered out everywhere the list renders (`getPackageComments`), row kept. Preserves the
  audit trail (same spirit as T0040's approval-authority work) and avoids cascade-delete
  cleanup on `package_comment_mentions`.
- **Edited indicator, not full version history** — nullable `updated_at`, "(edited)"
  shown whenever it's set. No revision-history/diff table (YAGNI — nobody's asked to see
  what a comment *used to* say).
- Only the author can edit/delete their own comment — enforced in `queries.ts`
  (`updatePackageComment`/`deletePackageComment` throw if `authorId` doesn't match), not
  just hidden in the UI.
- Migration applied directly to the `dev-darin` Neon branch (the one `.env.local` actually
  points at — see T0008/T0009 for why that matters).
