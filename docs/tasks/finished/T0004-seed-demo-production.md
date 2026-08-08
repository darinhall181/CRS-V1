---
title: Seed the Top Gun Maverick demo production properly
status: done
severity: high
type: task
component: db seed / pipeline
found_by: claude-code
found_date: 2026-08-05
completed_date: 2026-08-05
verified_live: false
github_issue: null
---

## Summary
Harpeth Valley Studios / Top Gun Maverick / DaVinci Rentals was the agreed
demo story (see rental-house-economics + altoscope-strategic-positioning
memory), but it was never actually seeded as real `companies` /
`productions` / `packages` rows. Package Builder still runs on an
in-memory client-side seed (`initialLineItems` in `page.tsx`), not
persisted data.

## Done
Seeded on the dev branch (`br-super-base-am9e7j58`, same branch `www` reads
from):
- `companies`: Harpeth Valley Studios (Darin as `owner`)
- `productions`: Top Gun Maverick — 18 shoot days, $105,880 budget, `active`
  (Darin as `coordinator`)
- `packages`: Camera Package
- `package_items`: EOS R5 C (sent), Canon EOS C70 (draft, second body —
  Maverick's real aerial/multi-cam work made two bodies the more honest
  seed than one), CN-E 30-105mm T2.8 (draft), CN-E 50mm T1.3 ×2 (draft)

Verified via a joined read-back query, not a browser — this is backend/data
work with no UI-visible symptom, so that's sufficient per `work-issue`'s
own rule.

## Notes
Unblocks T0003 (real production data) and T0005 (persisting line items) —
both now have a real production/package row to attach to.
