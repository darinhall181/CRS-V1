---
title: Build the Notification Center (bell icon is currently decorative)
status: open
severity: medium
type: task
component: www/src/app/(workspace)/package-builder/package-builder-topbar.tsx, www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
The bell icon added to Package Builder's top bar (`package-builder-topbar.tsx`) is
currently a plain unwired button — no unread state, no dropdown, no real notifications
behind it. Flagged by Darin as a real future need, not just a visual placeholder to leave
forever.

Needs, roughly:
- A `notification` table (recipient user, type, reference to whatever it's about,
  read/unread, created timestamp).
- Real triggers to write rows into it — the two closest candidates already in the
  codebase are T0008's `@mention` (mentioning someone should notify them) and the
  needs-attention style events T0043 (Dashboard) already sketched as "several small rule
  checks unioned together" (COI expiring, substitution proposed, quote expiring).
- The bell itself needs an unread-count badge and a dropdown/panel — this repo already
  has the visual pattern for a badge-count icon (Package Builder's old top bar had one on
  a "Package" icon, since removed) and for a dropdown (`DropdownMenu` used for the
  account cluster in the same top bar file).

## Notes
This is app-wide, not Package-Builder-specific — once real, the bell belongs in
whatever the eventual shared app shell becomes (see T0016), not duplicated per page.
Don't build it scoped to just this one page's top bar.
