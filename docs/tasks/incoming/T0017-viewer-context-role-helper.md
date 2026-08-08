---
title: getViewerContext() — one server-side resolver for user + roles
status: open
severity: high
type: task
component: www/src/lib/db/queries.ts, www/src/lib/auth.ts
found_by: claude-code
found_date: 2026-08-08
completed_date: null
verified_live: false
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
