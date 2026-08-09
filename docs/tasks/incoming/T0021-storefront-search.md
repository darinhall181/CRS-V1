---
title: Wire the search pill to product search
status: open
severity: medium
type: task
component: www/src/app/(app)/browse/, www/src/components/nav/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 2 (Storefront), 2 of 4. The nav search pill (T0016) submits to the storefront with
`?search=` — `getProducts` already supports ilike across full name / model / brand. Client
side: controlled input, debounce, push to URL params (server re-renders results).
SearchPill visual spec is in the Elevation Kit (segments split by 1px white @8%, 38px
circular blue submit).

Keep it dumb-simple: no typeahead dropdown, no fuzzy ranking in v1. If search quality
becomes a real complaint, that's a future task (pg_trgm or FTS), not this one.

## Verification
"alexa", "canon", partial model strings return sensible results; empty search clears the
param; back button restores the previous query.
