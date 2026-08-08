---
title: Build package_item_comment table + Notes panel persistence
status: open
severity: medium
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-05
completed_date: null
verified_live: false
github_issue: null
---

## Summary
The Notes panel in Package Builder's right rail has nothing to read/write
to — no comment table exists in `schema.ts`. Flagged as a demo-blocking gap
in the original design handoff.
