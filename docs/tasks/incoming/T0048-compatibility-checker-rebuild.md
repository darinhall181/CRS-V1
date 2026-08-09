---
title: Compatibility Checker — revisit/rebuild (scrapped as a standalone page)
status: open
severity: low
type: task
component: www/src/app/(app)/
found_by: claude-code
found_date: 2026-08-09
completed_date: null
verified_live: false
github_issue: null
---

## Summary
The standalone `/compatibility-checker` page was scrapped 2026-08-09 at Darin's
request — the shared `(app)` nav shell (T0016) had just landed, and clicking "Quotes"
in Package Builder's sidebar was routing into that old page with its own light shadcn
navbar, reading as a jarring mismatch against the new dark Elevation Kit shell everywhere
else. Rather than restyle a page whose future shape/placement is itself unsettled,
deleted it outright (`(app)/compatibility-checker/page.tsx` +
`compatibility-checker-client.tsx`) and filed this task to revisit properly later.

Darin's stated priority: Package Builder is what matters most right now. Compatibility
checking stays part of the product vision (per `CLAUDE.md`'s mount/media/power/physical
description) — this isn't a "never build it" call, just "not now, and not as it was."

## Notes
Darin's initial thinking, mid-conversation, worth preserving verbatim-ish rather than
losing to a summary: **compatibility checking may not deserve a standalone page at all —
it may belong folded into Browse (`/gear`) itself.** He specifically recalled that an
earlier skeleton/mockup of the site had compatibility checking integrated directly into
the gear/browse page, rather than as its own destination. If that's the direction, the
"Quotes" nav item (currently an inert placeholder, see `nav-items.tsx`) stays free for
whatever "Quotes" actually ends up meaning — a real quotes/RFQ list, most likely, once
T0031/T0032 land — rather than reclaiming this old page's route.

What's preserved and reusable when this gets picked back up:
- `checkCompatibility(cameraSlug, lensSlug)` and `getProductsByCategory(categorySlug)` in
  `www/src/lib/db/queries.ts` — deliberately **not** deleted, still real and correct
  (mount-type matching only today, not the full mount/media/power/physical vision).
- The removed page's UI (camera/lens dropdowns → compatible/incompatible verdict with
  notes) is a reasonable reference for whatever replaces it, whether that's a dedicated
  page again or a panel/mode within Browse.

Open questions for whoever picks this up:
1. Standalone page, or folded into Browse? (Darin's lean: folded into Browse.)
2. If folded into Browse — inline per-product ("check this lens against my camera" from
   a product card/detail view) vs. a separate mode/tab within the same page?
3. Does it belong in the main nav at all once it's not a standalone destination, or does
   it only surface contextually from within Browse/Package Builder?
