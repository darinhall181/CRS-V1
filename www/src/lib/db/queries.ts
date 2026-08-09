import { db } from "./index"
import { product, brand, productCategory, productSpec, specDefinition, specSection, rentalHouse, rentalHouseInventory, productions, packages, packageItems, productionMembers, companyMembers, companies } from "./schema"
import { eq, ilike, and, or, isNotNull, desc, asc } from "drizzle-orm"

// ─── Product Browse ───────────────────────────────────────────────────────────

export type ProductCard = {
  id: string
  slug: string
  fullName: string
  model: string
  primaryImageUrl: string | null
  msrpUsd: string | null
  brandName: string
  brandSlug: string
  categoryName: string
  categorySlug: string
}

export async function getProducts(opts: {
  categorySlug?: string
  brandSlug?: string
  search?: string
  limit?: number
} = {}): Promise<ProductCard[]> {
  const { categorySlug, brandSlug, search, limit = 60 } = opts

  const rows = await db
    .select({
      id: product.id,
      slug: product.slug,
      fullName: product.fullName,
      model: product.model,
      primaryImageUrl: product.primaryImageUrl,
      msrpUsd: product.msrpUsd,
      brandName: brand.name,
      brandSlug: brand.slug,
      categoryName: productCategory.name,
      categorySlug: productCategory.slug,
    })
    .from(product)
    .innerJoin(brand, eq(product.brandId, brand.id))
    .innerJoin(productCategory, eq(product.categoryId, productCategory.id))
    .where(
      and(
        eq(product.isActive, true),
        categorySlug ? eq(productCategory.slug, categorySlug) : undefined,
        brandSlug ? eq(brand.slug, brandSlug) : undefined,
        search
          ? or(
              ilike(product.fullName, `%${search}%`),
              ilike(product.model, `%${search}%`),
              ilike(brand.name, `%${search}%`)
            )
          : undefined
      )
    )
    .orderBy(asc(productCategory.displayOrder), asc(product.fullName))
    .limit(limit)

  return rows as ProductCard[]
}

// ─── Product Detail ───────────────────────────────────────────────────────────

export type SpecRow = {
  specValue: string | null
  unitUsed: string | null
  displayName: string
  normalizedKey: string
  dataType: string | null
  importance: number | null
  sectionName: string | null
  sectionOrder: number | null
}

export type ProductDetail = ProductCard & {
  manufacturerUrl: string | null
  specs: SpecRow[]
}

export async function getProductBySlug(slug: string): Promise<ProductDetail | null> {
  const [row] = await db
    .select({
      id: product.id,
      slug: product.slug,
      fullName: product.fullName,
      model: product.model,
      primaryImageUrl: product.primaryImageUrl,
      msrpUsd: product.msrpUsd,
      manufacturerUrl: product.manufacturerUrl,
      brandName: brand.name,
      brandSlug: brand.slug,
      categoryName: productCategory.name,
      categorySlug: productCategory.slug,
    })
    .from(product)
    .innerJoin(brand, eq(product.brandId, brand.id))
    .innerJoin(productCategory, eq(product.categoryId, productCategory.id))
    .where(and(eq(product.slug, slug), eq(product.isActive, true)))
    .limit(1)

  if (!row) return null

  const specs = await db
    .select({
      specValue: productSpec.specValue,
      unitUsed: productSpec.unitUsed,
      displayName: specDefinition.displayName,
      normalizedKey: specDefinition.normalizedKey,
      dataType: specDefinition.dataType,
      importance: specDefinition.importance,
      sectionName: specSection.sectionName,
      sectionOrder: specSection.displayOrder,
    })
    .from(productSpec)
    .innerJoin(specDefinition, eq(productSpec.specDefinitionId, specDefinition.id))
    .leftJoin(specSection, eq(specDefinition.sectionId, specSection.id))
    .where(and(eq(productSpec.productId, row.id), isNotNull(productSpec.specValue)))
    .orderBy(asc(specSection.displayOrder), desc(specDefinition.importance), asc(specDefinition.displayName))

  return { ...row, specs } as ProductDetail
}

// ─── Compatibility Check ──────────────────────────────────────────────────────

export type CompatibilityResult = {
  camera: ProductCard & { mountType: string | null }
  lens: ProductCard & { mountType: string | null; lensMount: string | null }
  compatible: boolean | null
  notes: string[]
}

async function getProductWithMount(slug: string, mountKey: string, lensKey?: string) {
  const base = await getProductBySlug(slug)
  if (!base) return null
  const mountSpec = base.specs.find((s) => s.normalizedKey === mountKey)
  const lensSpec = lensKey ? base.specs.find((s) => s.normalizedKey === lensKey) : undefined
  return { ...base, mountType: mountSpec?.specValue ?? null, lensMount: lensSpec?.specValue ?? null }
}

export async function checkCompatibility(
  cameraSlug: string,
  lensSlug: string
): Promise<CompatibilityResult | null> {
  const [camera, lens] = await Promise.all([
    getProductWithMount(cameraSlug, "lens_mount"),
    getProductWithMount(lensSlug, "lens_mount_type", "lens_mount_type"),
  ])

  if (!camera || !lens) return null

  const notes: string[] = []
  let compatible: boolean | null = null

  const camMount = camera.mountType?.toLowerCase().trim() ?? ""
  const lensMount = (lens.mountType ?? lens.lensMount ?? "").toLowerCase().trim()

  if (camMount && lensMount) {
    compatible = camMount === lensMount || camMount.includes(lensMount) || lensMount.includes(camMount)
    if (!compatible) {
      notes.push(
        `Camera uses ${camera.mountType} mount; lens is designed for ${lens.mountType ?? lens.lensMount} mount. An adapter may be required.`
      )
    } else {
      notes.push(`Mount types are compatible (${camera.mountType}).`)
    }
  } else {
    notes.push("Mount type data is incomplete — manual verification recommended.")
  }

  return {
    camera: { ...camera, mountType: camera.mountType },
    lens: { ...lens, mountType: lens.mountType, lensMount: lens.lensMount },
    compatible,
    notes,
  }
}

// ─── Products by category (for dropdowns) ────────────────────────────────────

export async function getProductsByCategory(categorySlug: string) {
  return getProducts({ categorySlug, limit: 500 })
}

// ─── Categories with product counts ───────────────────────────────────────────

export type CategoryCount = {
  slug: string
  name: string
  count: number
}

export async function getCategoriesWithCounts(): Promise<CategoryCount[]> {
  // Raw count query — Drizzle count() helper
  const rows = await db
    .select({
      slug: productCategory.slug,
      name: productCategory.name,
      id: productCategory.id,
    })
    .from(productCategory)
    .innerJoin(product, and(eq(product.categoryId, productCategory.id), eq(product.isActive, true)))
    .orderBy(asc(productCategory.displayOrder))

  // Group by slug client-side (simpler than a groupBy for small result sets)
  const map = new Map<string, CategoryCount>()
  for (const r of rows) {
    const existing = map.get(r.slug)
    if (existing) {
      existing.count++
    } else {
      map.set(r.slug, { slug: r.slug, name: r.name, count: 1 })
    }
  }

  return Array.from(map.values())
}

// ─── Rental house inventory ───────────────────────────────────────────────────
// Real vendor rates for products a given rental house actually stocks. Most of
// the catalog has no matching row yet — callers should treat this as an overlay
// on top of catalog data, not a full substitute for it.

export type RentalHouseRate = {
  productId: string
  rentalHouseName: string
  rentalHouseSlug: string
  dayRate: number
  weekRate: number | null
  quantityOnHand: number | null
  isAvailable: boolean | null
}

export async function getRentalHouseInventory(rentalHouseSlug: string): Promise<RentalHouseRate[]> {
  const rows = await db
    .select({
      productId: rentalHouseInventory.productId,
      rentalHouseName: rentalHouse.name,
      rentalHouseSlug: rentalHouse.slug,
      dayRate: rentalHouseInventory.dayRate,
      weekRate: rentalHouseInventory.weekRate,
      quantityOnHand: rentalHouseInventory.quantityOnHand,
      isAvailable: rentalHouseInventory.isAvailable,
    })
    .from(rentalHouseInventory)
    .innerJoin(rentalHouse, eq(rentalHouseInventory.rentalHouseId, rentalHouse.id))
    .where(eq(rentalHouse.slug, rentalHouseSlug))

  return rows.map((r) => ({
    ...r,
    dayRate: parseFloat(r.dayRate ?? "0"),
    weekRate: r.weekRate !== null ? parseFloat(r.weekRate) : null,
  }))
}

// ─── Productions & packages ────────────────────────────────────────────────────

export type Production = {
  id: string
  companyId: string
  name: string
  shootType: string | null
  shootDays: number | null
  totalBudget: number | null
  status: string
}

export async function getProduction(id: string): Promise<Production | null> {
  const rows = await db
    .select({
      id: productions.id,
      companyId: productions.companyId,
      name: productions.name,
      shootType: productions.shootType,
      shootDays: productions.shootDays,
      totalBudget: productions.totalBudget,
      status: productions.status,
    })
    .from(productions)
    .where(eq(productions.id, id))
    .limit(1)

  if (!rows[0]) return null
  return { ...rows[0], totalBudget: rows[0].totalBudget !== null ? parseFloat(rows[0].totalBudget) : null }
}

// Resolves "the" production for a signed-in user from their production_members
// rows — most recently active production they belong to. A user can belong to
// multiple productions; real production selection/routing (switching between
// them) is a separate, bigger feature — see TODO(T00xx) at the call site.
export async function getActiveProductionForUser(userId: string): Promise<Production | null> {
  const rows = await db
    .select({
      id: productions.id,
      companyId: productions.companyId,
      name: productions.name,
      shootType: productions.shootType,
      shootDays: productions.shootDays,
      totalBudget: productions.totalBudget,
      status: productions.status,
    })
    .from(productionMembers)
    .innerJoin(productions, eq(productionMembers.productionId, productions.id))
    .where(and(eq(productionMembers.userId, userId), eq(productions.status, "active")))
    .orderBy(desc(productions.updatedAt))
    .limit(1)

  if (!rows[0]) return null
  return { ...rows[0], totalBudget: rows[0].totalBudget !== null ? parseFloat(rows[0].totalBudget) : null }
}

export async function getCompany(id: string): Promise<{ id: string; name: string } | null> {
  const rows = await db.select({ id: companies.id, name: companies.name }).from(companies).where(eq(companies.id, id)).limit(1)
  return rows[0] ?? null
}

// ─── Membership / role resolution (T0017 — getViewerContext) ──────────────────

export type CompanyMemberRow = { role: "owner" | "admin" | "member" }
export type ProductionMemberRow = { role: "dp" | "coordinator" | "producer" | "gaffer"; department: string | null }

export async function getCompanyMember(companyId: string, userId: string): Promise<CompanyMemberRow | null> {
  const rows = await db
    .select({ role: companyMembers.role })
    .from(companyMembers)
    .where(and(eq(companyMembers.companyId, companyId), eq(companyMembers.userId, userId)))
    .limit(1)
  return rows[0] ?? null
}

export async function getProductionMember(productionId: string, userId: string): Promise<ProductionMemberRow | null> {
  const rows = await db
    .select({ role: productionMembers.role, department: productionMembers.department })
    .from(productionMembers)
    .where(and(eq(productionMembers.productionId, productionId), eq(productionMembers.userId, userId)))
    .limit(1)
  return rows[0] ?? null
}

export type PackageSummary = {
  id: string
  name: string
}

// A production can have multiple packages; for now this returns the first
// one (matches the current single-package-per-production demo state).
export async function getPackageByProduction(productionId: string): Promise<PackageSummary | null> {
  const rows = await db
    .select({ id: packages.id, name: packages.name })
    .from(packages)
    .where(eq(packages.productionId, productionId))
    .limit(1)

  return rows[0] ?? null
}

// ─── Package items ──────────────────────────────────────────────────────────

export type PackageItemRow = {
  id: string
  gearId: string
  qty: number
  status: string
}

export async function getPackageItems(packageId: string): Promise<PackageItemRow[]> {
  const rows = await db
    .select({
      id: packageItems.id,
      gearId: packageItems.gearId,
      qty: packageItems.quantity,
      status: packageItems.status,
    })
    .from(packageItems)
    .where(eq(packageItems.packageId, packageId))
    .orderBy(asc(packageItems.sortOrder))

  // gearId is nullable at the schema level (a line item not yet tied to a
  // catalog product) — filter those out rather than surfacing a bad row,
  // since every current write path always sets it.
  return rows
    .filter((r) => r.gearId !== null)
    .map((r) => ({ ...r, gearId: r.gearId as string }))
}

export async function addPackageItem(
  packageId: string,
  gearId: string,
  addedBy: string,
  qty: number = 1
): Promise<{ id: string }> {
  const [row] = await db
    .insert(packageItems)
    .values({ packageId, gearId, quantity: qty, status: "draft", addedBy })
    .returning({ id: packageItems.id })
  return row
}

export async function updatePackageItemQty(id: string, qty: number): Promise<void> {
  await db.update(packageItems).set({ quantity: qty }).where(eq(packageItems.id, id))
}

export async function removePackageItem(id: string): Promise<void> {
  await db.delete(packageItems).where(eq(packageItems.id, id))
}
