---
title: Implement real CSV export on Package Builder
status: done
severity: low
type: task
component: www/src/app/(workspace)/package-builder/package-builder-client.tsx
found_by: claude-code
found_date: 2026-08-05
completed_date: 2026-08-09
verified_live: true
github_issue: null
---

## Summary
**Done 2026-08-09:** Wired "Export CSV" to a real client-side `Blob`/`URL.createObjectURL`
download (`buildPackageCsv`/`downloadCsv` in `package-builder-client.tsx`) — no server
round-trip, as scoped. Exports the real, unfiltered package (category order, one row per
line item: Category/Item/Brand/SKU/Availability/Qty/Rate/Rate unit/Total), regardless of
the current search/group-by view state, since those are just a display lens on the same
data. Filename is `{production} - {package}.csv`, sanitized against illegal filesystem
characters. Button disabled when the package has zero items. Verified live: triggered a
real download, confirmed the saved file's rows and dollar-amount CSV-quoting
(`"$5,130"`) exactly match what's on screen.

"Export CSV" button is currently a visual stub with no click handler.
Client-side `Blob`/`URL.createObjectURL` is sufficient — no server
dependency needed.
