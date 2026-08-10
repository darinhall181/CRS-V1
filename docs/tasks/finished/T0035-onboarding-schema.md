---
title: Onboarding schema — workspace type, profession, and the working-details fields
status: done
severity: high
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: 2026-08-09
verified_live: true
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
- [x] `workspace_type`, `profession`, `onboarding_completed_at` columns on `users`
- [x] New `user_profile` table (minimal — T0029 extends it later)
- [x] Migration generated + pushed to the `dev-darin` Neon branch, schema.ts mirrored
- [x] Verified via a T0019 wizard run-through, row read-back

## Verification
**Done 2026-08-09:** Migration applied directly to `dev-darin` (the branch `.env.local`
actually points at). Existing users at the time of the migration were backfilled to
`onboarding_completed_at = now()` so the new redirect gate (T0019) doesn't retroactively
force them through the wizard — only brand-new signups get a null value. Verified via
several real signup → full-wizard run-throughs with direct DB read-back: `workspace_type`,
`profession` (+ conditional `default_production_role`), `experience_level`,
`home_market`/`referral_source`, and the full working-details set (`day_rate_band`,
`union_status`, `has_owner_kit`, `owner_kit_categories` array, `insurance_status` as a
comma-joined string for the prototype's multi-select chips) all round-tripped correctly.
