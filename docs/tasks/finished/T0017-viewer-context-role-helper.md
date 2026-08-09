---
title: getViewerContext() — one server-side resolver for user + roles
status: done
severity: high
type: task
component: www/src/lib/db/queries.ts, www/src/lib/auth.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: 2026-08-08
verified_live: true
github_issue: null
---

## Summary
Batch 0 (Foundations), 5 of 5. Supersedes the query half of T0007. One helper, called once
per request in server components:

```
getViewerContext() → {
  user,            // session user
  companyRole,     // owner | admin | member | null   (company_members)
  productionRole,  // dp | coordinator | producer | gaffer | null (production_members)
  department,      // gaffer scoping, null otherwise
}
```

Needs `getProductionMember(productionId, userId)` + `getCompanyMember(companyId, userId)`
in queries.ts. Pages pass the context down as props; role rules live in server components
(what gets *fetched*), not as client-side `if (role)` hiding. First consumer: nav (T0016)
showing role-appropriate entry points. Real payoff lands with T0026 (coordinator-only Send
quote), T0030 (rate visibility), T0032 (RFQ sides).

## Notes
Rental-house-side membership deliberately does NOT exist yet — that table arrives with the
RFQ batch (T0031). Design the return shape to accept a future `rentalHouseRole` without
breaking callers. UI-gating half of T0007 stays open and closes progressively via
T0026/T0030/T0032.

Returning both `companyRole` and `productionRole` here is deliberate and already
future-proofs **T0040** (blocked — undecided whether approval authority is gated by
company role or production role, since they can give different answers for the same
user). Don't resolve T0040's question inside this helper; just make sure both fields are
available to whichever consumer eventually needs them.

## Progress
- [x] `getCompanyMember(companyId, userId)` + `getProductionMember(productionId, userId)`
      in `www/src/lib/db/queries.ts`
- [x] `getViewerContext(productionId?)` in `www/src/lib/viewer-context.ts`
- [x] `package-builder/page.tsx` migrated off its ad-hoc `getSession` +
      `getActiveProductionForUser` combo onto the shared resolver
- [ ] Nav (T0016) consumes it for role-appropriate entry points — blocked on T0016's own
      open nav-shell direction, not on this helper
- [ ] T0026/T0030/T0032 close the UI-gating half progressively as those land

## Summary (2026-08-08)
Built `getViewerContext(productionId?)` returning `{ user, productionId, companyRole,
productionRole, department }` — `productionId` added beyond the original spec's shape
since callers need to know *which* production the roles are scoped to, not just the
roles themselves. Resolves the active production via the existing
`getActiveProductionForUser` when no `productionId` arg is given (same logic
`package-builder` used to inline), or an explicit one when passed — the future nav
company-switcher (T0016) will need the explicit form once a user can view a production
that isn't their "most recent active" one.

`Production`'s type/queries gained a `companyId` field (previously only `id`, `name`,
`shootType`, etc.) — needed to resolve `companyRole` from a production without a second
round trip through the production→company relation; backward compatible, no existing
caller was hurt by the addition.

**Verified live** against the running dev server (not a standalone `tsx` script — same
TLS-reset issue with a cold Neon compute as T0013's verification): a temporary route
handler exercised the no-session branch (returns `null`, correct) and the DB-lookup
branch directly against the T0004 seed data — `getCompanyMember`/`getProductionMember`
correctly resolved Darin as `owner` on Harpeth Valley Studios and `coordinator` on Top
Gun Maverick, matching the seed exactly. Route deleted immediately after. Confirmed
`package-builder` (`3004` local dev) still 307-redirects unauthenticated requests to
`/login` post-migration — behavior unchanged.

Not done: wiring this into nav — that's genuinely blocked on T0016's own undecided nav
shape, not a gap in this task. The UI-gating consumers (T0026/T0030/T0032) don't exist
yet either, so this helper currently has one real caller (`package-builder`, session/
production resolution only, no role gate yet to apply).
