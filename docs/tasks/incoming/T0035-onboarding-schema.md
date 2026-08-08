---
title: Onboarding schema — workspace type, profession, and the working-details fields
status: open
severity: high
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 1 (Login & onboarding), 2 of 3. The onboarding handoff captures answers that have
nowhere to land. Two changes, via the authoritative Drizzle path:

On `users` (identity-level facts):
```
workspace_type enum('production', 'rental', 'hobbyist')   -- step 1, drives routing
profession text                                           -- step 2 (10 values, wider than
                                                          --   the production_role enum)
onboarding_completed_at timestamptz                       -- gate for the wizard redirect
```

New `user_profile` table (created here minimally; **T0029 extends this same table** with
the full DP-profile fields rather than creating its own — update T0029's sketch when this
lands):
```
user_profile(user_id pk → users, home_market text, referral_source text,
             day_rate_band text, union_status text,
             owner_kit_categories text[], has_owner_kit boolean,
             insurance_status text)
```

Design notes:
- `profession` stays descriptive text; `production_role` remains the *authorization* enum.
  dp/coordinator/producer/gaffer professions also set `default_production_role`; the
  other six don't. Don't widen the enum for display purposes.
- Step-4 answers are coarse bands by design (chips, "Prefer not to say") — exact rates and
  real documents live in T0029's tables. Two granularities, two homes, no conflation.
- `workspace_type = 'rental'` records intent only; actual house linking is
  `rental_house_members` (T0031). Hobbyist = no memberships anywhere — fine by design.
- `experience_level` already exists on `users` — write Guided/Standard/Pro to it, no new
  column.

## Progress
- [ ] `workspace_type`, `profession`, `onboarding_completed_at` columns on `users`
- [ ] New `user_profile` table (minimal — T0029 extends it later)
- [ ] Migration generated + pushed to the Neon dev branch, schema.ts mirrored
- [ ] Verified via a T0019 wizard run-through, row read-back

## Verification
Migration generated + pushed to the Neon dev branch; schema.ts mirrored; a wizard
run-through (T0019) persists every step's answers, confirmed by row read-back.
