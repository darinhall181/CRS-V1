import { db } from "./index"
import { product, brand, productCategory, productSpec, specDefinition, specSection, rentalHouse, rentalHouseInventory, productions, packages, packageItems, packageComments, packageCommentMentions, packageDepartmentBudget, packageEvents, productionMembers, companyMembers, companies, users } from "./schema"
import { eq, ilike, and, or, isNotNull, isNull, desc, asc } from "drizzle-orm"

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
  updatedAt: Date
}

// A production can have multiple packages; for now this returns the first
// one (matches the current single-package-per-production demo state).
export async function getPackageByProduction(productionId: string): Promise<PackageSummary | null> {
  const rows = await db
    .select({ id: packages.id, name: packages.name, updatedAt: packages.updatedAt })
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

// T0025 — package_events written directly from each mutation as it happens
// (not reconstructed after the fact), in the same transaction as the write
// it's describing.

export async function addPackageItem(
  packageId: string,
  gearId: string,
  addedBy: string,
  qty: number = 1
): Promise<{ id: string }> {
  return db.transaction(async (tx) => {
    const [row] = await tx
      .insert(packageItems)
      .values({ packageId, gearId, quantity: qty, status: "draft", addedBy })
      .returning({ id: packageItems.id })
    await tx.update(packages).set({ updatedAt: new Date() }).where(eq(packages.id, packageId))
    const [gear] = await tx.select({ name: product.fullName }).from(product).where(eq(product.id, gearId))
    await tx.insert(packageEvents).values({
      packageId,
      actorId: addedBy,
      kind: "item_added",
      payload: { gearName: gear?.name ?? "an item", qty },
    })
    return row
  })
}

export async function updatePackageItemQty(id: string, qty: number, actorId: string): Promise<void> {
  await db.transaction(async (tx) => {
    const [item] = await tx
      .update(packageItems)
      .set({ quantity: qty })
      .where(eq(packageItems.id, id))
      .returning({ packageId: packageItems.packageId, gearId: packageItems.gearId })
    if (item) {
      await tx.update(packages).set({ updatedAt: new Date() }).where(eq(packages.id, item.packageId))
      const gear = item.gearId
        ? (await tx.select({ name: product.fullName }).from(product).where(eq(product.id, item.gearId)))[0]
        : undefined
      await tx.insert(packageEvents).values({
        packageId: item.packageId,
        actorId,
        kind: "item_qty_updated",
        payload: { gearName: gear?.name ?? "an item", qty },
      })
    }
  })
}

export async function removePackageItem(id: string, actorId: string): Promise<void> {
  await db.transaction(async (tx) => {
    const [item] = await tx
      .delete(packageItems)
      .where(eq(packageItems.id, id))
      .returning({ packageId: packageItems.packageId, gearId: packageItems.gearId })
    if (item) {
      await tx.update(packages).set({ updatedAt: new Date() }).where(eq(packages.id, item.packageId))
      const gear = item.gearId
        ? (await tx.select({ name: product.fullName }).from(product).where(eq(product.id, item.gearId)))[0]
        : undefined
      await tx.insert(packageEvents).values({
        packageId: item.packageId,
        actorId,
        kind: "item_removed",
        payload: { gearName: gear?.name ?? "an item" },
      })
    }
  })
}

// ─── Package comments (T0008) ───────────────────────────────────────────────

export type MentionableUser = {
  id: string
  name: string
}

// @mention candidates — real production_members only, not arbitrary users.
export async function getMentionableUsers(productionId: string): Promise<MentionableUser[]> {
  const rows = await db
    .select({ id: users.id, name: users.name })
    .from(productionMembers)
    .innerJoin(users, eq(productionMembers.userId, users.id))
    .where(eq(productionMembers.productionId, productionId))

  return rows
}

export type PackageCommentRow = {
  id: string
  body: string
  createdAt: Date
  updatedAt: Date | null
  authorId: string
  authorName: string
  mentionedUserIds: string[]
}

export async function getPackageComments(packageId: string): Promise<PackageCommentRow[]> {
  const comments = await db
    .select({
      id: packageComments.id,
      body: packageComments.body,
      createdAt: packageComments.createdAt,
      updatedAt: packageComments.updatedAt,
      authorId: packageComments.authorId,
      authorName: users.name,
    })
    .from(packageComments)
    .innerJoin(users, eq(packageComments.authorId, users.id))
    .where(and(eq(packageComments.packageId, packageId), isNull(packageComments.deletedAt)))
    .orderBy(asc(packageComments.createdAt))

  if (comments.length === 0) return []

  const mentionRows = await db
    .select({ commentId: packageCommentMentions.commentId, userId: packageCommentMentions.mentionedUserId })
    .from(packageCommentMentions)
    .where(
      or(...comments.map((c) => eq(packageCommentMentions.commentId, c.id)))
    )

  const mentionsByComment = new Map<string, string[]>()
  for (const row of mentionRows) {
    const list = mentionsByComment.get(row.commentId) ?? []
    list.push(row.userId)
    mentionsByComment.set(row.commentId, list)
  }

  return comments.map((c) => ({ ...c, mentionedUserIds: mentionsByComment.get(c.id) ?? [] }))
}

// mentionedUserIds is untrusted client input — cross-checked against real
// production_members below rather than recorded as-is, so a mention can only
// ever reference someone who actually has access to this production.
export async function addPackageComment(
  packageId: string,
  productionId: string,
  authorId: string,
  body: string,
  mentionedUserIds: string[]
): Promise<{ id: string; createdAt: Date }> {
  return db.transaction(async (tx) => {
    const [comment] = await tx
      .insert(packageComments)
      .values({ packageId, authorId, body })
      .returning({ id: packageComments.id, createdAt: packageComments.createdAt })

    if (mentionedUserIds.length > 0) {
      const validMembers = await tx
        .select({ userId: productionMembers.userId })
        .from(productionMembers)
        .where(
          and(
            eq(productionMembers.productionId, productionId),
            or(...mentionedUserIds.map((id) => eq(productionMembers.userId, id)))
          )
        )
      const validIds = new Set(validMembers.map((m) => m.userId))
      const rows = mentionedUserIds
        .filter((id) => validIds.has(id))
        .map((mentionedUserId) => ({ commentId: comment.id, mentionedUserId }))
      if (rows.length > 0) {
        await tx.insert(packageCommentMentions).values(rows)
      }
    }

    await tx.update(packages).set({ updatedAt: new Date() }).where(eq(packages.id, packageId))
    await tx.insert(packageEvents).values({
      packageId,
      actorId: authorId,
      kind: "comment_added",
      payload: { snippet: body.slice(0, 80) },
    })
    return comment
  })
}

// Only the author may edit/delete their own comment — enforced here, not
// just hidden in the UI. Throws rather than silently no-op-ing on a
// mismatch, so a caller bug surfaces instead of failing invisibly.
export async function updatePackageComment(id: string, authorId: string, body: string): Promise<void> {
  await db.transaction(async (tx) => {
    const [existing] = await tx
      .select({ authorId: packageComments.authorId, packageId: packageComments.packageId })
      .from(packageComments)
      .where(eq(packageComments.id, id))
    if (!existing) throw new Error("Comment not found.")
    if (existing.authorId !== authorId) throw new Error("Only the author can edit this comment.")

    await tx.update(packageComments).set({ body, updatedAt: new Date() }).where(eq(packageComments.id, id))
    await tx.update(packages).set({ updatedAt: new Date() }).where(eq(packages.id, existing.packageId))
  })
}

export async function deletePackageComment(id: string, authorId: string): Promise<void> {
  await db.transaction(async (tx) => {
    const [existing] = await tx
      .select({ authorId: packageComments.authorId, packageId: packageComments.packageId })
      .from(packageComments)
      .where(eq(packageComments.id, id))
    if (!existing) throw new Error("Comment not found.")
    if (existing.authorId !== authorId) throw new Error("Only the author can delete this comment.")

    await tx.update(packageComments).set({ deletedAt: new Date() }).where(eq(packageComments.id, id))
    await tx.update(packages).set({ updatedAt: new Date() }).where(eq(packages.id, existing.packageId))
  })
}

// ─── Package events (T0025) ─────────────────────────────────────────────────
// Backs the Package Builder "History" tab — package-scoped, deliberately not
// a global nav destination (T0016 decision, 2026-08-09).

export type PackageEventRow = {
  id: string
  kind: string
  payload: Record<string, unknown>
  createdAt: Date
  actorName: string | null
}

export async function getPackageEvents(packageId: string): Promise<PackageEventRow[]> {
  const rows = await db
    .select({
      id: packageEvents.id,
      kind: packageEvents.kind,
      payload: packageEvents.payload,
      createdAt: packageEvents.createdAt,
      actorName: users.name,
    })
    .from(packageEvents)
    .leftJoin(users, eq(packageEvents.actorId, users.id))
    .where(eq(packageEvents.packageId, packageId))
    .orderBy(desc(packageEvents.createdAt))

  return rows as PackageEventRow[]
}

// ─── Package department budgets (T0009) ─────────────────────────────────────
// Schema-only groundwork for now — no consuming UI yet (see schema.ts comment
// on packageDepartmentBudget for why: T0006/T0007 closed superseded, so this
// isn't gating a separate "Gaffer view" that doesn't exist). These are the
// basic read/write primitives a future budget-visibility rule would sit on
// top of, following T0030/T0032's query-level-scoping precedent rather than
// a new page.

export type PackageDepartmentBudgetRow = {
  id: string
  department: string
  approvedAmount: string
}

export async function getPackageDepartmentBudgets(packageId: string): Promise<PackageDepartmentBudgetRow[]> {
  return db
    .select({
      id: packageDepartmentBudget.id,
      department: packageDepartmentBudget.department,
      approvedAmount: packageDepartmentBudget.approvedAmount,
    })
    .from(packageDepartmentBudget)
    .where(eq(packageDepartmentBudget.packageId, packageId))
}

// One envelope per (package, department) — upsert rather than insert, so
// re-setting a department's budget updates it in place instead of erroring
// on the unique constraint.
export async function setPackageDepartmentBudget(
  packageId: string,
  department: string,
  approvedAmount: number,
  setBy: string
): Promise<{ id: string }> {
  const [row] = await db
    .insert(packageDepartmentBudget)
    .values({ packageId, department, approvedAmount: approvedAmount.toString(), setBy })
    .onConflictDoUpdate({
      target: [packageDepartmentBudget.packageId, packageDepartmentBudget.department],
      set: { approvedAmount: approvedAmount.toString(), setBy, updatedAt: new Date() },
    })
    .returning({ id: packageDepartmentBudget.id })
  return row
}
