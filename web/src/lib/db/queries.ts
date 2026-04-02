import { db } from "./index"
import { product, brand, productCategory, productSpec, specDefinition, specSection } from "./schema"
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
  search?: string
  limit?: number
} = {}): Promise<ProductCard[]> {
  const { categorySlug, search, limit = 60 } = opts

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
