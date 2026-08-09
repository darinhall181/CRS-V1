---
title: Saved items (hearts) — schema + storefront wiring
status: open
severity: low
type: task
component: www/src/lib/db/schema.ts, www/src/app/(app)/browse/
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

## Notes
**2026-08-09 — rethink the account-dropdown entry point.** Discussed with Darin: a
saved-items icon living prominently in the global top bar (à la a shopping cart) reads as
consumer e-commerce, which cuts against how this product has otherwise positioned itself
(marketing copy is "preproduction software," not "shop"; no cart/checkout metaphor
anywhere else). His read, which I agree with: keep the heart-toggle on gear cards as-is,
but surface "your saved items" contextually instead of via a global nav icon —
- A **"Saved" filter chip** in Browse (`/browse`), alongside the existing category chips —
  the natural place someone goes looking for gear they'd starred.
- A **quick-add source inside Package Builder's "Add gear" drawer** — saved items in
  service of actually building a package, which is closer to the real workflow this
  product is for than a cart-like browsing feature.
- The account-dropdown entry point from this task's original summary is now a maybe, not
  a given — keep it only as a low-emphasis secondary link if it's added at all, not the
  primary way to reach saved items.
