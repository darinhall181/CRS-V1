---
title: Packages root page (list/dashboard) + "New package" CTA modal
status: open
severity: medium
type: task
component: www/src/app/(workspace)/packages/, www/src/app/(workspace)/package-builder/
found_by: darin
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
New page, not previously tracked — a root `Packages` list view (sidebar nav item, sits
alongside Dashboard/Browse/Quotes/Settings) plus a "New package" CTA modal launched from
it. Darin shared two mockup screenshots for context; no files saved to a mockups folder
for this one, so the screenshots are the source of truth until this gets picked up.

Filed explicitly for context going into the Package Builder page work — the list page and
modal are the entry point into `package-builder`, so their fields (production, shoot
dates, approved budget, rate basis, starting rental house) define what package-builder
needs to receive/initialize from.

### 1. Packages list page (root)
- Header: "Packages" + subheading count ("5 packages · 2 active productions"), filter
  input, "New package" primary button (top right).
- Status filter tabs: All / Draft / Sent / Quote received / Approved / Confirmed, each
  with a count badge.
- Card grid: first card is always the "New package" empty-state card (dashed/subtle,
  "+", "Start empty, or duplicate an existing package as a base."). Remaining cards are
  one per package:
  - Title (e.g. "Top Gun Maverick — Camera Package"), status pill top-right
    (Sent/Approved/Draft/Quote received/Confirmed — color-coded)
  - Subtitle: production · rental house (e.g. "Paramount · DaVinci Rentals")
  - Big dollar figure: amount committed "of $X approved", with a progress bar underneath
    (bar color seems to vary — blue vs amber — likely tied to how close spend is to
    approved budget, needs confirming)
  - Footer row: item count · shoot day count, and relative last-updated ("just now",
    "4d ago", "3w ago")

### 2. "New package" modal (CTA)
Opened from either the empty-state card or the header button. Two-column layout:

**Left column**
- Package name (text input, placeholder "e.g. Cold Harbor — Camera Package")
- Production (text input, placeholder "Production company or client")
- Shoot dates (date range: start/end), with derived helper text below
  ("19 shoot days · 3 weeks at weekly rate")
- Approved budget (numeric input) + Rate basis toggle (Day rate / Weekly)
- "Start from" — three-way selector: Empty ("Build from scratch"), Duplicate ("Copy an
  existing package"), Template ("A-cam · doc · commercial")

**Right column**
- Shoot location (text input, e.g. "Los Angeles, CA")
- "N rental houses near {location}" panel with a "View on map" button (→ ties to
  T0028 rental-house map page) — lists nearby rental houses with distance, a status line
  per house (e.g. "Full package in stock", "2 items limited", "No quote in 30d"), and a
  selected/highlighted state (radio-like dot, first one pre-selected)
  - Helper copy: "Availability and day rates are pulled per house for your shoot dates.
    You can quote more than one and compare later." — implies this list is meant to be
    live/queried, not static, once real rental-house inventory/availability data exists
- Footer: live summary string ("Untitled package · 19d · Keslow Camera") + Cancel /
  "Create package" buttons

## Notes
- Both pieces are net-new — no existing route for a packages list; only
  `(workspace)/package-builder/` (the builder for a single package) exists today.
- **Package-builder needs to become per-package before this list page makes sense.**
  Today `(workspace)/package-builder/page.tsx` isn't parameterized — it resolves
  "the" package by looking up `getPackageByProduction(productionId)` for a hardcoded
  demo production (`DEMO_PRODUCTION_ID`), so there's only ever one package reachable.
  The DB side is already fine for this — `packages.id` (`schema.ts:432`) is already a
  real UUID primary key, no schema change needed. The actual gap is routing: this page
  needs to move to a dynamic segment (e.g. `package-builder/[packageId]/page.tsx`,
  reading `pkg.id` instead of deriving off `productionId`), so that:
  1. The Packages list page's cards link to `package-builder/{that package's real id}`.
  2. The "Create package" button in the New Package modal actually inserts a new
     `packages` row and redirects into the builder at its freshly-created id.
  3. Duplicate/Template start options (modal) become "insert a row copied from X" instead
     of no-ops.
  Worth doing this routing change as its own preparatory step before/alongside building
  the list page, since the list page's card links depend on it existing.
- The "N rental houses near {location}" panel implies a real geo query against rental
  house data (see T0027 rental-house-geo-seed, T0028 rental-house-map-page) — don't build
  it as static/mocked data if that dependency is already in place by the time this is
  picked up.
- Status pill vocabulary here (Draft/Sent/Quote received/Approved/Confirmed) should be
  reconciled with whatever package-builder/other pages already use — T0045 flagged that
  package-level status is currently only derived client-side from line-item statuses in
  `package-builder-client.tsx`, not a real field.
- "Duplicate"/"Template" start options in the modal aren't wired to real behavior in the
  mockup — scope as follow-up if picked up as UI-only first.
