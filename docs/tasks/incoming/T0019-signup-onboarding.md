---
title: Post-signup onboarding — role, company, and invitation acceptance
status: open
severity: medium
type: task
component: www/src/app/login/, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 1 (Login & onboarding), 2 of 2. Today a fresh signup lands in the app with no
company, no production, no role — every role-aware surface (T0017 onward) would render
empty. Minimal onboarding after first sign-up:

1. Pick what you do → writes `users.default_production_role` (dp / coordinator / producer /
   gaffer — enum already exists).
2. Create a company (name → `companies` + `company_members` owner row) **or** accept a
   pending invitation: the `invitations` table (email, token, roles, expiry) is fully
   modeled and completely unused — wire token lookup → membership rows → `accepted_at`.

Out of scope: production creation UI (packages still hang off the seeded demo production
until real production routing exists), email sending (invitation links can be copy-paste
for now).

## Verification
Fresh account → onboarding → lands in app with a real company membership row; invited
account joins the existing company with the invited role. Both confirmed by DB read-back.
