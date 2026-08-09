---
title: Find a real home for "Find substitute" (pulled from the Detail panel for now)
status: blocked
severity: low
type: task
component: www/src/app/(workspace)/package-builder/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
The Package Builder Detail panel (line-item detail, right rail) had a "Find substitute"
button next to "Duplicate" — inherited from the `Package Builder - Elevation.dc.html`
handoff, sitting there with no real behavior wired up. Darin flagged it as feeling
out of place ("random") and asked to pull it for now rather than leave a dead button,
but the underlying need — swapping an unavailable/limited item for a compatible
alternative — is real and worth solving properly later.

Removed from `DetailPanel` in `package-builder-client.tsx` (kept "Duplicate", which
does have a clear, obvious behavior even though it's not wired to a real handler yet
either).

## Notes
Open question: where should this actually live?
- Inline on the item row itself, next to the "Out N days"/"Limited" availability text
  (contextual — appears exactly where the problem is visible)
- A dedicated action in the bulk-selection bar ("N selected" → "Find substitute"),
  batchable across several flagged rows at once
- Folded into the catalog drawer — opening "Add gear" pre-filtered to
  compatibility-checked alternatives for the item being replaced

Whichever direction, it likely wants to lean on the compatibility-checker's existing
matching logic (`checkCompatibility` in `www/src/lib/db/queries.ts`) rather than being
a new, separate matching implementation.

**2026-08-08 — punted, this is bigger than a UI placement call.** Asked Darin to pick
between the three options above; his answer was that "find substitute" can't really be
decided in isolation — it depends on a not-yet-decided sequencing question in the
rental-house workflow:

- Does a production build the package (line items) first, and only *then* see which
  rental houses near the shoot location (T0047's location field) actually have that
  inventory? Substitute-finding would then mean "this rental house doesn't have it —
  who does / what's close."
- Or does picking a rental house happen earlier, with the package built against that
  house's known inventory from the start — in which case "substitute" is closer to
  "this house is out of stock, here's what else they have."
- Rental-house data itself is a wildcard here too — whether a house's inventory/
  availability is real-time-queryable depends on what that specific house publishes
  (their own site, a feed, manual quote-request only), which affects whether
  "find substitute" can ever be a live query vs. always routing through a request/quote
  step (T0031 quote-document-layer, T0032 rfq-dual-role-page).

Not resolving placement until that sequencing decision gets made — likely as part of
scoping T0047 (packages root page — the "N rental houses near {location}" modal panel
is the first place this ordering question becomes concrete) or a dedicated workflow
decision doc alongside T0039/T0040's role-taxonomy/approval-authority precedent. Leaving
this task open but blocked on that, not implementing a placement guess in the meantime.
