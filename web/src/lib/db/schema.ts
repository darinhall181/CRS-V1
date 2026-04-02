import {
  pgTable,
  uuid,
  text,
  boolean,
  integer,
  numeric,
  timestamp,
  doublePrecision,
  jsonb,
  unique,
} from "drizzle-orm/pg-core"
import { relations } from "drizzle-orm"

// ─── brand ───────────────────────────────────────────────────────────────────

export const brand = pgTable("brand", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  slug: text("slug").notNull().unique(),
  websiteUrl: text("website_url"),
  logoUrl: text("logo_url"),
  scrapingEnabled: boolean("scraping_enabled").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
})

// ─── product_category ────────────────────────────────────────────────────────

export const productCategory = pgTable("product_category", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  slug: text("slug").notNull().unique(),
  parentCategoryId: uuid("parent_category_id"),
  displayOrder: integer("display_order").default(0),
  iconName: text("icon_name"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
})

// ─── spec_section ─────────────────────────────────────────────────────────────

export const specSection = pgTable(
  "spec_section",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    sectionName: text("section_name").notNull(),
    categoryId: uuid("category_id"),
    displayOrder: integer("display_order").default(0),
    parentSectionId: uuid("parent_section_id"),
  },
  (t) => [unique().on(t.sectionName, t.categoryId)]
)

// ─── spec_definition ──────────────────────────────────────────────────────────

export const specDefinition = pgTable("spec_definition", {
  id: uuid("id").primaryKey().defaultRandom(),
  sectionId: uuid("section_id"),
  displayName: text("display_name").notNull(),
  normalizedKey: text("normalized_key").notNull().unique(),
  dataType: text("data_type").default("text"),
  unit: text("unit"),
  categoryId: uuid("category_id"),
  description: text("description"),
  importance: integer("importance").default(0),
})

// ─── product ──────────────────────────────────────────────────────────────────

export const product = pgTable("product", {
  id: uuid("id").primaryKey().defaultRandom(),
  brandId: uuid("brand_id").notNull(),
  categoryId: uuid("category_id").notNull(),
  model: text("model").notNull(),
  fullName: text("full_name").notNull(),
  slug: text("slug").notNull().unique(),
  sku: text("sku"),
  msrpUsd: numeric("msrp_usd"),
  primaryImageUrl: text("primary_image_url"),
  manufacturerUrl: text("manufacturer_url"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
})

// ─── product_spec ─────────────────────────────────────────────────────────────

export const productSpec = pgTable("product_spec", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id").notNull(),
  specDefinitionId: uuid("spec_definition_id").notNull(),
  specValue: text("spec_value"),
  rawValue: text("raw_value"),
  rawValueJsonb: jsonb("raw_value_jsonb"),
  numericValue: numeric("numeric_value"),
  minValue: numeric("min_value"),
  maxValue: numeric("max_value"),
  unitUsed: text("unit_used"),
  booleanValue: boolean("boolean_value"),
  extractionConfidence: doublePrecision("extraction_confidence"),
  scrapedAt: timestamp("scraped_at", { withTimezone: true }).defaultNow(),
})

// ─── product_image ────────────────────────────────────────────────────────────

export const productImage = pgTable("product_image", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id").notNull(),
  url: text("url").notNull(),
  kind: text("kind"),
  sortOrder: integer("sort_order").default(0),
  source: jsonb("source"),
  rawMetadata: jsonb("raw_metadata"),
})

// ─── product_document ─────────────────────────────────────────────────────────

export const productDocument = pgTable("product_document", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id").notNull(),
  documentKind: text("document_kind"),
  url: text("url").notNull(),
})

// ─── Relations ────────────────────────────────────────────────────────────────

export const brandRelations = relations(brand, ({ many }) => ({
  products: many(product),
}))

export const productCategoryRelations = relations(productCategory, ({ many, one }) => ({
  products: many(product),
  parent: one(productCategory, {
    fields: [productCategory.parentCategoryId],
    references: [productCategory.id],
    relationName: "categoryParent",
  }),
}))

export const productRelations = relations(product, ({ one, many }) => ({
  brand: one(brand, { fields: [product.brandId], references: [brand.id] }),
  category: one(productCategory, { fields: [product.categoryId], references: [productCategory.id] }),
  specs: many(productSpec),
  images: many(productImage),
}))

export const specDefinitionRelations = relations(specDefinition, ({ one, many }) => ({
  section: one(specSection, { fields: [specDefinition.sectionId], references: [specSection.id] }),
  productSpecs: many(productSpec),
}))

export const productSpecRelations = relations(productSpec, ({ one }) => ({
  product: one(product, { fields: [productSpec.productId], references: [product.id] }),
  definition: one(specDefinition, { fields: [productSpec.specDefinitionId], references: [specDefinition.id] }),
}))

export const productImageRelations = relations(productImage, ({ one }) => ({
  product: one(product, { fields: [productImage.productId], references: [product.id] }),
}))

// ─── Types ────────────────────────────────────────────────────────────────────

export type Brand = typeof brand.$inferSelect
export type ProductCategory = typeof productCategory.$inferSelect
export type Product = typeof product.$inferSelect
export type ProductSpec = typeof productSpec.$inferSelect
export type SpecDefinition = typeof specDefinition.$inferSelect
export type SpecSection = typeof specSection.$inferSelect
export type ProductImage = typeof productImage.$inferSelect
