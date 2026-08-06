---
title: Logo/nav bar centers instead of staying pinned left on wide screens
status: in-progress
severity: medium
type: bug
component: www/src/components/nav/navbar.tsx
found_by: claude-browser
found_date: 2026-08-05
verified_live: true
github_issue: "#11"
---

## Summary
Above roughly 1152px+padding viewport width, the entire nav row (logo,
links, sign-in) centers itself in the header instead of the logo staying
pinned to the left edge.

## How it was found
Claude resized the browser window to 1920px then 2560px wide via
`resize_window`, screenshotted the header, and confirmed via
`getComputedStyle` that the nav row's parent div caps at 1152px
(`max-w-6xl`) and is horizontally centered (`mx-auto`) inside the
full-width header.

## Root cause
In `navbar.tsx`, the row div has className
`"mx-auto flex h-14 max-w-6xl items-center justify-between px-4 sm:px-6"`.
`mx-auto` + `max-w-6xl` centers the whole flex row within the full-width
header at large viewports.

## Suggested fix
Remove `mx-auto max-w-6xl`, e.g. change to
`"flex h-14 w-full items-center justify-between px-4 sm:px-6 lg:px-8"` so
`justify-between` spans the full header width and the logo stays pinned
left at any screen size.

## Repro steps
1. `bun dev`, open any page
2. Resize browser window to ~1920px+ wide
3. Observe logo/nav floating centered instead of hugging the left edge

## Status
Fix applied 2026-08-05 by claude-code — replaced `mx-auto ... max-w-6xl`
with `w-full ... lg:px-8` in `navbar.tsx`. **Not yet re-verified live** — no
browser access in this session; only confirmed the dev server builds clean.
