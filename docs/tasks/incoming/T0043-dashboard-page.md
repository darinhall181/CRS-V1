---
title: Dashboard page — production/rental home screen
status: open
severity: medium
type: task
component: www/src/app/(app)/dashboard/, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
New page, not previously tracked — identified from `Dashboard.dc.html` (in `~/Downloads/
Altoscope Gear Storefront Redesign (3)/`), the app's home screen after sign-in. Shares the
app shell whose exact shape is still open (T0016 — the Dashboard mockup is itself one of
the three inputs to that decision).

**One page, two audiences** (role-symmetric, same shape, different labels/data, matching
the T0041/T0042 pattern): production-workspace users see their own package/quote/schedule
state; rental-house-workspace users see their incoming-request/inventory/prep state.

**Greeting + primary action:** "Good morning, {name}" + one-line status summary, one
sunset-free primary button (production: "New package"; rental: "New quote" — this screen
has no sunset CTA, per the Elevation Kit's one-per-screen rule already spent elsewhere).

**4 stat cards:** production — packages in progress, quotes awaiting response, days until
pickup, needs-attention count. Rental — open requests, quotes awaiting client, days until
next prep, needs-attention count. Same 4-card shape, different numbers/labels.

**Two-column body:**
- Left: **Active packages/requests list** (title/meta, status pill, progress bar + mono
  figure, "View all" link) and a **Budget vs. approved** (production) / **Committed
  inventory** (rental) panel — same progress-bar-per-row shape, different rows.
- Right rail: **"Needs attention"** action items (icon well + title/note, sunset-tinted
  dot in the section header), **Upcoming/Prep & pickup schedule** (date bubble + event
  title/meta), **Recent activity** feed (dot + text + mono relative time).

## Progress
- [ ] Stat-card aggregation queries (packages/quotes/schedule counts, both workspace types)
- [ ] Active packages/requests list with real status + progress data
- [ ] Budget vs. approved panel (production) / committed inventory panel (rental)
- [ ] Needs-attention action items (real triggers, not mockup placeholders — see Notes)
- [ ] Upcoming schedule panel
- [ ] Recent activity feed
- [ ] Role-symmetric behavior verified for both workspace types

## Notes
Mostly buildable earlier than T0041/T0042 — its data (packages, package_items, quotes,
budget categories) is already planned schema, no new tables obviously needed, unlike CRM's
contact-log gap or History's dependency on T0033. The **rental-workspace variant** is the
exception: "open requests," "committed inventory," and a rental-house's own prep schedule
all assume rental-house-side membership and data, which doesn't exist until **T0031**
(Batch 6). Build the production-workspace variant first; the rental variant is naturally
gated on T0031 regardless of when this task starts.

"Needs attention" items in the mockup are heterogeneous (COI expiring, a substitution
proposed, a quote expiring) — this isn't one query, it's several small rule checks unioned
together. Don't try to force it into a single query; a short list of independent checks
(each cheap, each optional) composed at render time is the right shape.

Nav item list inconsistency noted on T0016 applies here too — this mockup's own sidebar is
one of the ones missing the "History" nav entry that CRM/History include.

## Verification
Both workspace types render with real data (not the mockup's fictional Vantage
Pictures/Keslow West figures); stat cards match what the underlying list panels actually
show (no drift between a card's count and the rows below it); needs-attention items link
to the real record they're about.
