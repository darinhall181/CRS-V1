---
title: Package notes thread + change log (lands T0008)
status: open
severity: medium
type: task
component: www/src/lib/db/schema.ts, www/src/app/(app)/package-builder/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
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
"History" nav item (currently an inert placeholder in `nav-items.tsx`, part of T0016's
6-item shell) doesn't reflect how history actually gets used — almost all of it is
package-scoped ("what happened to *this* package"), not a cross-app destination. Decision:
- Remove "History" from the global left nav — not yet executed in code, recorded here
  first at Darin's request.
- Once `package_event` exists, surface it as a tab on Package Builder itself, alongside
  Detail/Budget/Notes — this is the "under the base of the packages page" Darin described,
  landing on the single-package view (package-builder) rather than T0047's packages *list*
  page, since a change log belongs to one package, not the list of them.
- A cross-package "recent activity" feed on Dashboard (T0043) is a plausible secondary
  surface later, but lower priority and not required for this task — don't build it
  speculatively.

**2026-08-09 — `package_comments` needs edit/delete, revise the schema before building
more on top of it.** Darin flagged the Notes panel needs real edit/delete, not just
post-only. Recommendation (not yet built):
- **Soft-delete**, not hard `DELETE` — add a nullable `deleted_at` to `package_comments`.
  Filter `WHERE deleted_at IS NULL` everywhere the list renders, but keep the row. In a
  tool where "who said what and who approved what" matters (same spirit as T0040's
  approval-authority work), silently losing comment history on delete is worse than one
  free column. Also keeps `package_comment_mentions` rows intact rather than needing
  cascade-delete cleanup logic.
- **Edited indicator, not full version history.** Add a nullable `updated_at` (or reuse
  `created_at`/compare) — show "(edited)" in the UI whenever `updated_at != created_at`.
  This is the Slack/Discord pattern and is enough for v1. Do **not** build a full
  revision-history/diff table for this pass — nobody's asked to see what a comment *used
  to* say, and storing+rendering every revision is a meaningfully bigger feature than the
  need in front of us (YAGNI here specifically).
- Only the author should be able to edit/delete their own comment — enforce in the server
  action (`addPackageCommentAction`'s siblings), not just hidden in the UI.
- This is a schema change on top of what T0008 already shipped — needs its own
  `db:generate`/apply pass (see T0008/T0009's session notes for the "wrong Neon branch"
  gotcha: `.env.local` points at `dev-darin`, not the default `production` branch).
