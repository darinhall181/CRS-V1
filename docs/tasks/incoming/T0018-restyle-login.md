---
title: Default auth page — onboarding step 0 split-screen layout + Google sign-in
status: open
severity: medium
type: task
component: www/src/app/login/page.tsx, www/src/lib/auth.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
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
- [ ] Split-screen layout (brand panel + auth card) on the elevation token system
- [ ] Google OAuth wired into `lib/auth.ts` (`socialProviders.google`)
- [ ] "Forgot password" affordance (stub is acceptable, must be honest about its state)
- [ ] Post-auth routing: `next` param for existing users, wizard redirect for incomplete
      onboarding

## Notes
Depends on T0015 (tokens); T0034 primitives make it cheaper but aren't a hard dependency.
Supersedes the earlier restyle-only scope of this task.
