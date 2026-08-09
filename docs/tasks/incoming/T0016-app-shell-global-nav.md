---
title: App shell v2 — global nav + shared (app) layout per the design handoffs
status: in-progress
severity: medium
type: task
component: www/src/components/nav/, www/src/app/(app)/layout.tsx
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: true
github_issue: null
---

## Summary
Batch 0 (Foundations), 4 of 5. Replace the current light shadcn navbar with the handoff's
flat global nav (72px, base surface, no border/shadow): logo mark + wordmark left, centered
underline tabs (Browse · Packages · Quote), account cluster right ("Hello, {name}" +
Account & projects dropdown). The Storefront variant adds the centered search pill and the
package-count badge (count of current package's items — real query, not a prop).

One shared `(app)/layout.tsx` owns the shell so the five screens only render their body.
Account dropdown holds sign-out, saved items (T0023 entry point), and later profile link.

## Direction (2026-08-08, leaning but not locked)
The top-nav spec above comes from the original Storefront handoff and is now superseded.
A newer exploration doc, `Navigation Options.dc.html` (in `~/Downloads/Altoscope Gear
Storefront Redesign (3)/`), lays out three alternatives side by side with explicit
tradeoffs; the three newer mockups (Dashboard, CRM, History — same folder) all
consistently render **option 1a**. **Steer from Darin: a hybrid, leaning more toward 1a**
(the CRM page's sidebar) rather than a pure pick of any single option below — exact hybrid
shape still to be worked out when this task is actually picked up, not guessed at now:

- **1a — left sidebar (236–216px), full labels + workspace switcher.** Every destination
  visible at once; switcher lives in the sidebar. Costs real width — "noticeable on the
  three-pane package builder" (the handoff's own words). This is what Dashboard.dc.html,
  CRM.dc.html, and History.dc.html all actually use.
- **1b — top nav, full-width content.** Reads as continuous with the marketing site, gives
  all width back to content. Caps out around six destinations; the workspace switcher
  competes with the account menu for top-bar space. Closest to this task's current spec.
- **1c — 64px icon rail + contextual top bar.** Cheapest on width; icon-only destinations
  need hover labels, "a real learning cost early on" per the handoff.

Nav item lists also differ slightly between the newer mockups' sidebars: Dashboard.dc.html
production nav has 6 items (no History entry); CRM.dc.html/History.dc.html production nav
has 7 (History inserted between Rental houses and Budget). Reconcile when building —
likely just a stale omission in Dashboard.dc.html, not intentional.

## Notes
Depends on T0015 (tokens). The Rental House Map screen has its own shrinking-header
variant — that stays local to the map page (T0028), not in the shared shell.

The workspace switcher (production company ↔ rental-house company, e.g. "Vantage
Pictures" / "Keslow West" in the mockups) is the company-context differentiator flagged in
T0040's permissions notes — solo users don't need it at all. Whichever nav shape wins,
solo (no company) accounts should not see a switcher with nothing to switch to.

## Progress
- [x] Replaced the old light shadcn `<Navbar/>` with a real shared shell —
  `(app)/app-shell.tsx`, wired in via `(app)/layout.tsx` (now an async server component
  resolving viewer + company, same pattern as `package-builder/page.tsx`)
- [x] Shell = full-width `TopBar` above a flush, collapsible `SidebarNav` — the leaning
  hybrid-toward-1a direction, reusing the exact primitives already validated on Package
  Builder rather than a new build
- [x] Nav destinations, logo, and account/sign-out menu extracted to shared modules
  (`components/nav/nav-items.tsx`, `logo.tsx`, `account-menu.tsx`) so Package Builder's
  own shell and this one can't drift — updated `package-builder-sidebar.tsx`/`-topbar.tsx`
  to consume the same modules instead of duplicating
  (`package-builder-sidebar.tsx` also picked up real `usePathname()`-based active-item
  state instead of a hardcoded `label === "Packages"` check, as a side benefit)
- [x] Solo-account workspace-switcher omission verified — falls out of `SidebarNav`'s
  existing `workspaces` prop behavior (already the case for Package Builder), not new
  code
- [x] Verified live: Browse and Compatibility Checker both render inside the new shell
  with correct active-nav-item highlighting; Package Builder (separate `(workspace)`
  shell, deliberately not unified — see below) confirmed unaffected by the shared-module
  extraction
- [x] **2026-08-09 update** — nav list expanded to the full 6-item shape per explicit
  direction from Darin: Dashboard/Browse/Packages/Quotes/History/CRM, + Settings below
  the divider. Only Browse/Packages are real destinations; the rest (`href: null` in
  `nav-items.tsx`) render in the shell but are deliberately inert (no click handler)
  rather than routing to "/" — landing a signed-in user on the public marketing page read
  as a bug, not a coming-soon state, once there were 4 placeholder items instead of 2.
  This supersedes the item below — no longer blocked on the external handoff files, this
  is now the decided shape regardless of what those mockups show.
- [ ] ~~full nav-item-list reconciliation against the actual `Navigation
  Options.dc.html`/`Dashboard.dc.html`/`CRM.dc.html`/`History.dc.html` handoff files~~ —
  superseded, see above.
- [ ] **Not done, and scope revised** — account dropdown still only has sign-out.
  "Saved items" (T0023) is now planned to live in Browse/the Add-gear drawer instead of
  the account dropdown (2026-08-09, see T0023's Notes) — a global cart-like icon read as
  too consumer/e-commerce for this product. A profile link stays a maybe, no destination
  exists yet either way.
- [x] **"History" removed from this nav entirely** (2026-08-09) — relocated to a Package
  Builder tab instead (package-scoped history is the common case, not a global
  destination). `nav-items.tsx` no longer lists it; see T0025 for the `package_events`
  table + tab it now lands on.
- [ ] **Out of scope, not blocking** — Dashboard/CRM don't exist as real pages yet
  (T0043/T0041), so "one shared layout so the five screens only render their body"
  is only true for the 2 of 5 nav items that currently resolve to a real page (Browse,
  Packages). The shell has a slot for Dashboard/CRM whenever they land. Compatibility
  Checker (the "Quotes" placeholder's previous destination) was scrapped outright, not
  folded into this shell — see T0048.

Package Builder intentionally keeps its own page-scoped shell rather than moving into
this one — the task's own notes flag exactly why (1a "costs real width — noticeable on
the three-pane package builder"). Unifying that is a separate, bigger call, not a side
effect of this pass.
