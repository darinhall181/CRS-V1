---
title: Onboarding wizard — workspace, profession, profile, working details, ready (steps 1–5)
status: open
severity: high
type: task
component: www/src/app/onboarding/, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 1 (Login & onboarding), 3 of 3. Scope revised 2026-08-08: build the onboarding flow
from `~/Downloads/handoff_onboarding/Onboarding.dc.html` (steps 1–5; step 0 is T0018).
Schema fields come from T0035 — do that first.

- **Step 1 · Workspace**: Production · Rental house · Hobbyist — single select, writes
  `users.workspace_type`, drives routing for the rest of the flow and the app.
- **Step 2 · Profession** (skippable): 10 options (dp, photographer, videographer, 1st AC,
  producer, coordinator, gaffer, dit, rental, other) → `users.profession`. Where it maps
  onto the `production_role` enum (dp/coordinator/producer/gaffer), also set
  `users.default_production_role`; the other six professions leave it null.
- **Step 3 · Profile**: name, home market, experience level (Guided/Standard/Pro →
  existing `users.experience_level`), referral source.
- **Step 4 · Working details** (all optional, **skipped entirely for hobbyist**): day-rate
  band chips, union status, owner-operator kit categories + toggle, insurance status.
  These are coarse bands, not the exact figures — T0029's profile tables hold the precise
  versions later; onboarding must never demand precision a new user doesn't want to give.
- **Step 5 · Ready**: four entry cards (build a package → package-builder, find rental
  houses → map, import a gear list → stub, complete your profile → profile). Sets
  `onboarding_completed_at`.
- Mechanics per the prototype: clickable progress dots (Working-details dot hidden for
  hobbyists), back/next with the hobbyist step-4 bypass (3 → 5), selected-card treatment
  (`inset 0 0 0 1.5px #4D68C0` on elevation/1). Persist each step's answers as the user
  advances (server action per step), not one big submit — abandoning at step 3 should
  still keep steps 1–2.

Company creation / invitation acceptance (this task's original scope) is **not** in the
designed flow. Keep it minimal and downstream: production-workspace users who hit a
surface needing a company (first production) get the simple create/join form; the
`invitations` token path from the original scope still gets wired there. Rental-house
users: store the workspace choice now; actual `rental_house_members` linking arrives with
T0031 (Batch 6) — until then they land in the app with a "house tools coming" state.
Hobbyists have no memberships at all — `getViewerContext()` (T0017) already returns null
roles, and nothing may crash on that.

## Open question (2026-08-08 workshop, not yet resolved)
A separate planning session proposed a "solo or studio?" fork right after sign-up
(solo → create productions immediately, no company; studio → name a company, atomic
`companies` + `companyMembers` owner row). Not yet decided whether/how this competes or
complements Step 1's workspace_type select above — resolve when this task is actually
picked up, don't guess now. Company-model schema this would need (`productions.companyId`
nullable, `companies.companyType`) is captured separately in T0037 regardless of how the
UI question gets asked. Likely relevant scope: only `workspace_type = production` users
need this fork at all — hobbyists are already solo by design (no memberships), rental
company structure is separate future work (T0031).

## Progress
- [ ] Step 1 · Workspace select → `users.workspace_type`
- [ ] Step 2 · Profession (skippable) → `users.profession` + conditional
      `default_production_role`
- [ ] Step 3 · Profile (name, home market, experience level, referral source)
- [ ] Step 4 · Working details (skipped for hobbyist) → coarse-band fields
- [ ] Step 5 · Ready — entry cards, sets `onboarding_completed_at`
- [ ] Per-step persistence (server action per step, not one big submit)
- [ ] Downstream company create/join form (production-workspace users only)
- [ ] Verification: three fresh accounts, one per workspace type

## Verification
Three fresh accounts, one per workspace type: hobbyist never sees step 4 and its dot;
mid-flow abandon at step 3 retains steps 1–2 in the DB; completed flow sets
`onboarding_completed_at` and next sign-in goes straight to the app, not the wizard.
