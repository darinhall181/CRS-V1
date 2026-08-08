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
