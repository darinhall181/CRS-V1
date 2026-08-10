// T0019/T0035 — shared between the wizard UI (client) and the server actions
// that validate/derive from it. Values match Onboarding.dc.html exactly.

export type WorkspaceType = "production" | "rental" | "hobbyist"

export const WORKSPACE_OPTIONS: { value: WorkspaceType; label: string; body: string }[] = [
  { value: "production", label: "Production", body: "Build packages, validate gear, and send quote requests." },
  { value: "rental", label: "Rental house", body: "Receive requests, price packages, and manage inventory." },
  { value: "hobbyist", label: "Hobbyist", body: "Shoot for yourself, rent occasionally, learn the gear." },
]

export type ProductionRole = "dp" | "coordinator" | "producer" | "gaffer"

export interface ProfessionOption {
  id: string
  label: string
  /** Only 4 of the 10 professions also set users.defaultProductionRole. */
  productionRole: ProductionRole | null
}

export const PROFESSION_OPTIONS: ProfessionOption[] = [
  { id: "dp", label: "DP", productionRole: "dp" },
  { id: "photographer", label: "Photographer", productionRole: null },
  { id: "videographer", label: "Videographer", productionRole: null },
  { id: "ac", label: "1st AC", productionRole: null },
  { id: "producer", label: "Producer", productionRole: "producer" },
  { id: "coord", label: "Coordinator", productionRole: "coordinator" },
  { id: "gaffer", label: "Gaffer", productionRole: "gaffer" },
  { id: "dit", label: "DIT", productionRole: null },
  { id: "rental", label: "Rental house", productionRole: null },
  { id: "other", label: "Other", productionRole: null },
]

export const HOME_MARKET_OPTIONS = ["Los Angeles, CA", "New York, NY", "Atlanta, GA", "Chicago, IL", "Austin, TX"]

export const EXPERIENCE_LEVELS = ["Guided", "Standard", "Pro"] as const

export const RATE_BAND_OPTIONS = ["$500 – 900", "$900 – 1,400", "$1,400 – 2,200", "$2,200+", "Prefer not to say"]

export const UNION_STATUS_OPTIONS = ["Non-union", "Local 600 eligible", "Local 600 member", "Other guild"]

export const KIT_CATEGORY_OPTIONS = ["Camera body", "Lens set", "Support", "Monitoring", "Wireless video", "Lighting"]

export const INSURANCE_OPTIONS = ["General liability COI", "Equipment rider", "Not yet"]

export function productionRoleForProfession(professionId: string | null): ProductionRole | null {
  return PROFESSION_OPTIONS.find((p) => p.id === professionId)?.productionRole ?? null
}
