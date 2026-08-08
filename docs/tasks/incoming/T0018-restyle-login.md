---
title: Restyle login/signup to the elevation design system
status: open
severity: low
type: task
component: www/src/app/login/page.tsx
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Batch 1 (Login & onboarding), 1 of 2. The login flow already works (Better Auth
email+password, sign-in/sign-up toggle, `next` redirect). This is a pure restyle to the
token system: dark base surface, surface/02 card at elevation/1, standard focus ring,
sunset accent reserved for nothing here (login has no send/publish action — primary button
is interactive blue). Keep the existing shadcn primitives and all current logic.

No dedicated login mockup exists in the handoffs — compose from the Elevation Kit
primitives (Button, input wells on surface/01, card spec) and the handoff's voice/tone
rules ("errors state the fact, never apologize").

## Notes
Depends on T0015/T0016. Do together with T0019 so the signup → onboarding flow ships as
one piece.
