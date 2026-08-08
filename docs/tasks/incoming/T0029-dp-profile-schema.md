---
title: DP profile schema — profile, owned kit, credits, rates, documents, house accounts, crew
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
Batch 5 (Profile), 1 of 2. The largest schema gap in the plan: `users` carries only
name/email/avatar/roles, while the DP Profile mockup's information model needs eight
blocks. New tables (all keyed to `users.id`):

```
user_profile: EXTEND the table T0035 creates (do not create a second one) with
             headline, bio, city, region, years_experience, genres text[],
             is_verified, availability_status, available_from, available_to
             -- union_status already lands there via T0035 (onboarding step 4)
user_owned_gear(id, user_id, product_id → product nullable, custom_name, description,
                day_rate numeric, sort_order)          -- owner-operator package
user_credit(id, user_id, title, kind, director, year, platform, shot_on, still_url, sort_order)
user_rate(id, user_id, kind enum(day_10hr, half_day, prep_scout, overtime_hr), amount, unit)
user_document(id, user_id, kind enum(coi_general, equipment_insurance, w9, drone_cert, other),
              title, file_url, coverage_amount numeric nullable, expires_on date nullable, status)
user_rental_house_account(id, user_id, rental_house_id → rental_house, terms, account_number,
                          jobs_count int default 0)
user_crew(id, user_id, crew_user_id → users nullable, display_name, role, sort_order)
```

Design notes:
- `user_owned_gear.product_id` nullable with `custom_name` fallback — DPs own gear the
  catalog doesn't have; don't block profile completeness on pipeline coverage.
- `user_document.expires_on` drives the green/amber expiry dots; COI coverage fields here
  are the same shapes the RFQ COI panel (T0031) reads — one documents table, two surfaces.
- `user_crew.crew_user_id` nullable: regular crew usually aren't Altoscope users yet;
  display_name carries them until they are.
- Packages & quotes block needs NO new table — it's the user's packages joined through
  `package_item_quote` (query in T0030).
- Skip a `ratings`/endorsement system entirely; `is_verified` is an admin-set boolean.

## Progress
- [ ] Extend T0035's `user_profile` table (do not create a second one) with the profile
      fields above
- [ ] `user_owned_gear` table
- [ ] `user_credit` table
- [ ] `user_rate` table
- [ ] `user_document` table
- [ ] `user_rental_house_account` table
- [ ] `user_crew` table
- [ ] Migration via the authoritative path, schema.ts mirrored
- [ ] Seed Darin's own profile as the demo DP, joined read-back verified

## Notes
Depends on T0035 landing first — this task extends its `user_profile` table rather than
creating its own; if T0035 hasn't shipped yet, do that one first.

## Verification
Migration via the authoritative path (T0013 decision), schema.ts mirrored, seed Darin's
own profile as the demo DP with 2–3 rows per table, joined read-back clean.
