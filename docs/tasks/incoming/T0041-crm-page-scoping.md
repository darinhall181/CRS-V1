---
title: CRM page — relationship tracking for rental houses / clients
status: open
severity: medium
type: task
component: www/src/app/(app)/crm/, www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Now scoped — a real prototype landed (`CRM.dc.html` in `~/Downloads/Altoscope Gear
Storefront Redesign (3)/`), superseding this task's original "not yet scoped" state.
Shares the app shell (sidebar, workspace switcher, top bar) whose exact shape is still
open — see T0016.

**One page, two audiences (role-symmetric, same shape, different label):**
- Production-workspace users manage **rental houses** they work with.
- Rental-house-workspace users manage **clients** (production companies) they serve.

**List view:** title/subtitle, role-labeled "Add rental house"/"Add client" button, filter
chips (All / Active / Quoting / Prospects / Dormant, each with a live count) + search.
Table columns: Account (avatar-initials + name + location), Preferred contact (name +
role), Linked productions (lead title + "+N" overflow), Last contact (date + via +
color-coded recency), Open value (mono $). Row click selects an account.

**Detail drawer** (fixed right-side panel, 376px, slides over content — not a route):
header (initials, name, location, close), status chip + "working together since" date, a
2×2 metrics grid (open quotes / lifetime spend / avg turnaround / on-time prep for the
production view; open quotes / lifetime revenue / avg rental / on-time return for the
rental view — same shape, different labels), preferred-contact block (avatar, name/role,
email + phone rows, primary CTA "Send request"/"Send quote" + "Log contact" button),
linked-productions list (dot + title/meta + mono value, clickable), and a contact-history
timeline (dot + text + mono relative time).

## Progress
- [ ] Schema: what's derivable vs. what needs new tables (see Notes — status classification
      and contact-log entries are the two pieces without an obvious existing home)
- [ ] List view: table, filter chips with live counts, search
- [ ] Detail drawer: metrics, preferred contact, linked productions, contact history
- [ ] Role-symmetric behavior verified for both production and rental-house workspaces

## Notes
**Schema gap, not fully solved by existing tables.** Some of this is derivable from what's
already planned (linked productions + open value ← `productions`/`package_item_quote`,
per T0031; "since" ← earliest shared production). Two pieces aren't:
- **Account status** (active/quoting/prospect/dormant) — this reads as either a computed
  bucket (derive from recency + open-quote state, no storage) or a manually-set field. The
  mockup's data has houses with zero linked productions still showing as "Prospect" with a
  contact-history entry (an intro call, no rental yet) — that specific case can't be purely
  derived from productions/quotes, since there's nothing to derive from yet. Lean toward:
  status is computed where derivable, with a manual override field for the "not yet
  transacted" edge case.
- **Contact history / activity log** — the timeline entries in the mockup ("Dana emailed
  about new inventory," "Call — prep bay availability," "COI updated") are freeform CRM
  notes, not existing domain events. Needs a small table (e.g. `crm_activity_log`:
  companyId or rentalHouseId, authorId, body, createdAt) — this is a different table from
  T0025's package-level notes/change-log, since it's relationship-scoped, not
  package-scoped.
- **Preferred contact** — a house/client can have multiple people; the mockup shows one
  "preferred" contact per account. Simplest shape: a nullable `preferredContactName`/
  `Email`/`Phone`/`Role` set of fields directly on `rentalHouse` (production view) and on
  `companies` or a new lightweight client-contact table (rental view) — don't over-build a
  full multi-contact-per-account model unless the mockup's "preferred contact" singular
  framing turns out to be wrong.

Depends on T0037 (company model — this page's rental-house-workspace side needs company
context to exist) and interacts with T0031 (quotes feed "open value"/"linked productions").
Not blocked on T0016's nav-shell decision, just shares whatever shell wins.

## Verification
Both workspace types render the same page shape with role-correct labels/columns/metrics.
Filter chip counts match the actual filtered row count. Selecting a row opens the drawer
with real linked-production and contact-history data, not mockup placeholders.
