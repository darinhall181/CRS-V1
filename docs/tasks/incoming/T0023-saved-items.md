---
title: Saved items (hearts) — schema + storefront wiring
status: open
severity: low
type: task
component: www/src/lib/db/schema.ts, www/src/app/(app)/gear/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 2 (Storefront), 4 of 4. First new-table task — intentionally tiny to exercise the
migration path settled in T0013 before the big schema batches (T0029/T0031).

```
saved_product(id, user_id → users, product_id → product, created_at,
              unique(user_id, product_id))
```

Heart button on gear cards (optimistic toggle via server action), saved list reachable
from the account cluster dropdown (T0016). That's the whole feature.

## Verification
Toggle survives refresh; unique constraint holds on double-toggle races; migration applied
via the authoritative path and mirrored in schema.ts.
