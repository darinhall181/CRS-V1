---
title: Implement real CSV export on Package Builder
status: open
severity: low
type: task
component: www/src/app/(app)/package-builder/package-builder-client.tsx
found_by: claude-code
found_date: 2026-08-05
completed_date: null
verified_live: false
github_issue: null
---

## Summary
"Export CSV" button is currently a visual stub with no click handler.
Client-side `Blob`/`URL.createObjectURL` is sufficient — no server
dependency needed.
