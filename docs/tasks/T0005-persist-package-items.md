---
title: Persist Package Builder line items to package_items (not just in-memory state)
status: open
severity: high
type: task
component: www/src/app/(app)/package-builder/
found_by: claude-code
found_date: 2026-08-05
verified_live: false
github_issue: null
---

## Summary
`PackageBuilderClient` holds line items in React state only — nothing
writes to the real `package_items` table. Need
`addPackageItem`/`updatePackageItemStatus`/`removePackageItem` query
functions plus wiring so changes survive a page refresh.

## Notes
Depends on T0004 (real production/package to attach items to).
