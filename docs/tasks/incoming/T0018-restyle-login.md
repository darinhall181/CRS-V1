---
title: Default auth page — onboarding step 0 split-screen layout + Google sign-in
status: in-progress
severity: medium
type: task
component: www/src/app/login/page.tsx, www/src/lib/auth.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: true
github_issue: null
---

## Summary
Batch 1 (Login & onboarding), 1 of 3. Scope revised 2026-08-08: a dedicated login design
now exists — step 0 of the onboarding handoff (`~/Downloads/handoff_onboarding/
Onboarding.dc.html` + its README). **Decision (Darin): this layout is the default auth
page** — every sign-in, not just first-run onboarding, renders it.

- Split screen: brand panel left (arch mark on base surface), auth card right on the
  elevation token system (surface/02 card, surface/01 input wells, 10px radii, standard
  focus ring). Interactive blue primary button; no sunset on this screen (the flow's one
  sunset is "Finish setup ↗" on Working details).
- Auth methods: **Google OAuth + email/password** (per the handoff — account required for
  all users). Google is new: configure Better Auth `socialProviders.google` in
  `lib/auth.ts` + client/env vars. Keep the existing email/password + `next`-param logic.
- Includes "Forgot password" affordance (Better Auth reset flow — can be a stub link in
  v1 if the email path isn't wired yet; state that fact honestly in the UI, don't fake it).
- Post-auth routing: existing users → `next` target as today; users who haven't completed
  onboarding (`users.onboarding_completed_at` null, T0035) → the wizard (T0019).

## Progress
- [x] Split-screen layout (brand panel + auth card) on the elevation token system —
      built once from Darin's written description, then rebuilt to match the actual
      `Onboarding.dc.html` handoff (pasted in-session 2026-08-09) pixel-for-pixel where it
      specifies exact values: `--surface-page-shell` (#101012) brand panel, 44px logo,
      34px/300-weight headline with the handoff's real copy, `--surface-01`/`--surface-02`
      card surfaces, 46px-tall inputs/buttons, 10px radii. Verified live: real sign-in
      round-trip (`next`-param redirect to `/package-builder`) still works; sign-in ↔
      sign-up mode toggle confirmed clean (fixed a bug where the "Forgot password" notice
      leaked into sign-up mode — wasn't gated by `mode`).
- [ ] Google OAuth wired into `lib/auth.ts` (`socialProviders.google`) — **not done**, no
      client ID/secret exist anywhere in this repo. The "Continue with Google" button *is*
      built and styled exactly per the handoff (real multi-color G icon), but is an honest
      stub: clicking it shows "Google sign-in isn't set up yet — use email below." rather
      than pretending to authenticate. Wire the real provider once credentials exist.
- [x] "Forgot password" affordance — stub, honest about its state ("Password reset isn't
      set up yet — contact your workspace admin for now."), same pattern as the Google stub.
- [ ] Post-auth routing: `next` param for existing users works (unchanged, verified live).
      Wizard redirect for incomplete onboarding — **not done**, blocked on T0035
      (`users.onboarding_completed_at` doesn't exist yet) and T0019 (the wizard itself
      isn't built, so there's nowhere to redirect to).

## Notes
Depends on T0015 (tokens); T0034 primitives make it cheaper but aren't a hard dependency.
Supersedes the earlier restyle-only scope of this task.

**2026-08-09** — this only covers step 0 ("· Log in") of `Onboarding.dc.html`. Steps 1–5
(workspace/role/profile/working-details/done) are T0019's scope, not touched here — that
task needs T0035's schema first regardless.
