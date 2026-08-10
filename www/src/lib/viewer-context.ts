import { getSession } from "./session"
import {
  getActiveProductionForUser,
  getProduction,
  getCompanyMember,
  getProductionMember,
  getOnboardingCompletedAt,
} from "./db/queries"

export interface ViewerContext {
  user: { id: string; name: string; email: string }
  /** The production this context is scoped to — null if the viewer has none yet. */
  productionId: string | null
  companyRole: "owner" | "admin" | "member" | null
  productionRole: "dp" | "coordinator" | "producer" | "gaffer" | null
  /** Scopes a department-lead's (gaffer, etc.) authority — null otherwise. */
  department: string | null
  /** Null means the onboarding wizard (T0019) hasn't been completed yet —
   * every protected layout redirects to /onboarding when this is null. */
  onboardingCompletedAt: Date | null
}

// T0017 — one server-side resolver for user + roles, called once per request in
// server components. Role rules live in server components (what gets *fetched*),
// not as client-side `if (role)` hiding — see T0026/T0030/T0032 for the actual
// gates consuming this. Rental-house-side membership deliberately doesn't exist
// yet (arrives with T0031); callers should treat productionRole/companyRole as
// the only two role fields for now, not assume a third is coming without checking.
//
// Doesn't resolve T0040 (company-role vs. production-role approval authority) —
// both fields are returned so whichever answer that lands on has what it needs.
export async function getViewerContext(productionId?: string): Promise<ViewerContext | null> {
  const session = await getSession()
  if (!session) return null

  const [production, onboardingCompletedAt] = await Promise.all([
    productionId ? getProduction(productionId) : getActiveProductionForUser(session.user.id),
    getOnboardingCompletedAt(session.user.id),
  ])

  if (!production) {
    return {
      user: session.user,
      productionId: null,
      companyRole: null,
      productionRole: null,
      department: null,
      onboardingCompletedAt,
    }
  }

  const [companyMember, productionMember] = await Promise.all([
    getCompanyMember(production.companyId, session.user.id),
    getProductionMember(production.id, session.user.id),
  ])

  return {
    user: session.user,
    productionId: production.id,
    companyRole: companyMember?.role ?? null,
    productionRole: productionMember?.role ?? null,
    onboardingCompletedAt,
    department: productionMember?.department ?? null,
  }
}
