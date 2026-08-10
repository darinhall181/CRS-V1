---
title: Onboarding wizard — workspace, profession, profile, working details, ready (steps 1–5)
status: done
severity: high
type: task
component: www/src/app/onboarding/, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: 2026-08-09
verified_live: true
github_issue: null
---

## Summary (2026-08-09)
**Done:** All five steps built at `www/src/app/onboarding/` (`page.tsx` +
`onboarding-client.tsx` + `actions.ts` + `constants.ts`), matching
`Onboarding.dc.html` (pasted in-session) closely — copy, chip/toggle behavior, selected-
card treatment (reused `SELECTED_CARD_RING`, already the app's canonical selected-state
primitive, instead of the handoff's slightly different one-off blue), Guided/Standard/Pro
via the existing `SegmentedToggle` primitive, the owner-kit toggle via the existing
`Switch` primitive. Icons are lucide substitutes for the handoff's hand-drawn SVGs (this
app already uses lucide everywhere else) rather than ported 1:1 — a deliberate, scoped
deviation, not an oversight.
Every real protected page (`(app)/layout.tsx`, `package-builder/page.tsx`) now redirects
to `/onboarding` when `viewer.onboardingCompletedAt` is null, via an extended
`ViewerContext` (T0017's resolver). Verified live end-to-end multiple times: real signup →
redirect into the wizard, per-step persistence confirmed by DB read-back after each step,
hobbyist correctly skips step 4 and its progress dot, "Back" from Ready correctly returns
to step 3 for hobbyists / step 4 for everyone else, reaching "Ready" sets
`onboarding_completed_at` and clicking "Build a package" lands in a fully-functional
`/package-builder` (gate passes on the next request). Existing pre-migration accounts
(backfilled, see T0035) confirmed unaffected — sign in goes straight to the app.

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

## Open question (2026-08-08 workshop) — resolved 2026-08-09
A separate planning session proposed a "solo or studio?" fork right after sign-up
(solo → create productions immediately, no company; studio → name a company, atomic
`companies` + `companyMembers` owner row). **Resolved: not added to this wizard.** This
task's own scope statement already answered it — "Company creation / invitation
acceptance... is not in the designed flow. Keep it minimal and downstream" — so building
the 5-step handoff flow as designed, with no company-fork step inserted, is exactly what
was scoped, not a gap. Company creation/joining stays exactly where this task always said
it should: a simple create/join form shown downstream, whenever a production-workspace
user first hits a surface that actually needs a company (not built as part of this task —
nothing in the current app requires a company yet). Company-model schema (T0037) is
unaffected either way.

## Progress
- [x] Step 1 · Workspace select → `users.workspace_type`
- [x] Step 2 · Profession (skippable) → `users.profession` + conditional
      `default_production_role`
- [x] Step 3 · Profile (name, home market, experience level, referral source)
- [x] Step 4 · Working details (skipped for hobbyist) → coarse-band fields
- [x] Step 5 · Ready — entry cards, sets `onboarding_completed_at`
- [x] Per-step persistence (server action per step, not one big submit)
- [ ] **Not done** — downstream company create/join form. Genuinely out of scope for this
      pass: nothing in the current app yet has a surface that requires a production to
      have a company, so there's nothing to attach this form to. Build it when that
      surface exists.
- [x] Verification: multiple fresh accounts covering production (with and without
      profession/working-details filled in) and hobbyist workflows

## Verification
**Done 2026-08-09, verified live:** hobbyist never sees step 4 or its dot (confirmed: 4
dots render instead of 5, and Next from step 3 jumps straight to step 5); "Back" from
step 5 correctly returns to step 3 for hobbyists / step 4 otherwise; each step's DB write
confirmed independently via direct read-back (not just "the final state looked right");
reaching step 5 sets `onboarding_completed_at` and immediately unlocks
`/package-builder` in the same session (redirect gate re-checked, passes); pre-existing
accounts (backfilled by T0035's migration) sign in straight to the app, confirmed
unaffected.

Not separately tested: the literal "abandon at step 3, close the tab, come back" resume
case. What *is* confirmed is the underlying mechanism it depends on — every step's answer
lands in the DB immediately when you click Next/Skip, independent of whether you ever
reach step 5 — so a real abandon behaves the same as the tested "skip most steps" runs
already verified above, just cut off earlier. The wizard itself always restarts at step 1
on reload (matches the prototype's own SPA-reset behavior) but pre-fills every field from
whatever's already saved — see `onboarding-client.tsx`'s top comment.
