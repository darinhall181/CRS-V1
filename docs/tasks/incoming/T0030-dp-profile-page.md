---
title: DP Profile page with query-level rate visibility
status: open
severity: high
type: task
component: www/src/app/(app)/profile/
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 5 (Profile), 2 of 2. Build `DP Profile.dc.html` as `/profile/[userId]` (own profile
at `/profile`): identity header (avatar, verified badge, availability line, sunset
"Request availability" CTA), section nav, two-column body — owner-operator kit, packages &
quotes table, credits left; rates, insurance & docs, house accounts, regular crew right.

The role rule that matters (per the mockup's own information model): **rates are hidden
from producers until a quote request** — implement at the query boundary: the profile
query takes the viewer context (T0017) and simply doesn't select `user_rate` rows for
non-owner production viewers. Not CSS hiding. Owner sees everything; rental-house viewers
(future) see owned kit prominently (the avoid-double-quoting purpose).

Packages & quotes table: the user's packages with house, dates, total (sum of selected
quotes × days), status pill — statuses map from `package_item_status` rollup.

## Notes
Depends on T0029. Own-profile *editing* is v1-minimal: a plain settings form for
user_profile fields is enough; rich editors for credits/kit can be follow-up tasks.
"Request availability" can open a mailto/composer stub until messaging exists.
