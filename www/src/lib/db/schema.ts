import {
  pgTable,
  pgEnum,
  uuid,
  text,
  boolean,
  integer,
  numeric,
  timestamp,
  date,
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

// ─── spec_mapping ─────────────────────────────────────────────────────────────

export const specMapping = pgTable("spec_mapping", {
  id: uuid("id").primaryKey().defaultRandom(),
  specDefinitionId: uuid("spec_definition_id").notNull().references(() => specDefinition.id),
  extractionPattern: text("extraction_pattern").notNull(),
  contextPattern: text("context_pattern"),
  manufacturerKey: text("manufacturer_key"),
  priority: integer("priority").default(0),
  notes: text("notes"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
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
  upc: text("upc"),
  announceDate: date("announce_date"),
  msrpUsd: numeric("msrp_usd"),
  currentPriceUsd: numeric("current_price_usd"),
  primaryImageUrl: text("primary_image_url"),
  thumbnailUrl: text("thumbnail_url"),
  manufacturerUrl: text("manufacturer_url"),
  sourceUrl: text("source_url"),
  rawData: jsonb("raw_data"),
  lastScrapedAt: timestamp("last_scraped_at", { withTimezone: true }),
  scrapingStatus: text("scraping_status").default("pending"),
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

// ─── product_spec_matrix ──────────────────────────────────────────────────────

export const productSpecMatrix = pgTable(
  "product_spec_matrix",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    productId: uuid("product_id").notNull().references(() => product.id, { onDelete: "cascade" }),
    specDefinitionId: uuid("spec_definition_id").notNull().references(() => specDefinition.id, { onDelete: "cascade" }),
    dims: jsonb("dims").notNull(),
    valueText: text("value_text"),
    numericValue: numeric("numeric_value"),
    unitUsed: text("unit_used"),
    widthPx: integer("width_px"),
    heightPx: integer("height_px"),
    isAvailable: boolean("is_available").notNull().default(true),
    isInexactProportion: boolean("is_inexact_proportion").notNull().default(false),
    notes: text("notes"),
    extractionConfidence: doublePrecision("extraction_confidence"),
    scrapedAt: timestamp("scraped_at", { withTimezone: true }).defaultNow(),
  },
  (t) => [unique().on(t.productId, t.specDefinitionId, t.dims)]
)

// ─── product_image ────────────────────────────────────────────────────────────

export const productImage = pgTable("product_image", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id").notNull(),
  url: text("url").notNull(),
  kind: text("kind"),
  sortOrder: integer("sort_order").default(0),
  sourceUrl: text("source_url"),
  source: jsonb("source"),
  rawMetadata: jsonb("raw_metadata"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
})

// ─── product_document ─────────────────────────────────────────────────────────

export const productDocument = pgTable("product_document", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id"),
  brandSlug: text("brand_slug"),
  productType: text("product_type"),
  productSlug: text("product_slug"),
  documentKind: text("document_kind").notNull(),
  title: text("title"),
  url: text("url").notNull(),
  sourceUrl: text("source_url"),
  status: text("status").default("discovered"),
  discoveredAt: timestamp("discovered_at", { withTimezone: true }).defaultNow(),
  downloadedAt: timestamp("downloaded_at", { withTimezone: true }),
  localPath: text("local_path"),
  rawMetadata: jsonb("raw_metadata"),
})

// ─── compatibility_axis ───────────────────────────────────────────────────────
//
// Defines the standardized dimensions on which kit compatibility is evaluated.
// Seed with the 7 core axes: lens_mount, sensor_format, rod_system,
// power_standard, recording_media, signal_output, gear_pitch.

export const compatibilityAxis = pgTable("compatibility_axis", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  slug: text("slug").notNull().unique(),
  description: text("description"),
  // "enum" = discrete values like "PL" / "LPL"
  // "range" = numeric range like min/max
  // "boolean" = feature present or not
  valueType: text("value_type").notNull().default("enum"),
  displayOrder: integer("display_order").default(0),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
})

// ─── product_compatibility_value ──────────────────────────────────────────────
//
// Per-product value for each compatibility axis.
// isInput = true  → this product *accepts* this value (e.g. camera accepts PL mount)
// isInput = false → this product *provides* this value (e.g. lens has PL mount)
// A product can have multiple rows per axis — e.g. ALEXA 35 accepts both LPL and PL.

export const productCompatibilityValue = pgTable(
  "product_compatibility_value",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    productId: uuid("product_id").notNull().references(() => product.id, { onDelete: "cascade" }),
    axisId: uuid("axis_id").notNull().references(() => compatibilityAxis.id, { onDelete: "cascade" }),
    value: text("value").notNull(),   // e.g. "PL", "LPL", "15mm_lws", "gold_mount"
    isInput: boolean("is_input").default(true),
    notes: text("notes"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (t) => [unique().on(t.productId, t.axisId, t.value)]
)

// ─── product_relationship ─────────────────────────────────────────────────────
//
// Encodes known relationships between products for the kit builder's
// "you'll also need..." and "incompatible with" prompts.
//
// Examples:
//   ALEXA 35 → requires → ARRI PL-to-LPL Adapter  (if using PL lenses)
//   ALEXA 35 → recommends → Anton Bauer CINE 90    (Gold Mount battery)
//   Teradek Bolt TX → requires → Teradek Bolt RX    (needs its receiver)

export const productRelationshipTypeEnum = pgEnum("product_relationship_type", [
  "requires",
  "recommends",
  "replaces",
  "incompatible_with",
  "optional_upgrade",
])

export const productRelationship = pgTable(
  "product_relationship",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    sourceProductId: uuid("source_product_id").notNull().references(() => product.id, { onDelete: "cascade" }),
    targetProductId: uuid("target_product_id").notNull().references(() => product.id, { onDelete: "cascade" }),
    relationshipType: productRelationshipTypeEnum("relationship_type").notNull(),
    isConditional: boolean("is_conditional").default(false),  // true = only required under certain conditions
    conditionNote: text("condition_note"),                     // e.g. "Only if using PL lenses on ALEXA 35"
    notes: text("notes"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (t) => [unique().on(t.sourceProductId, t.targetProductId, t.relationshipType)]
)

// ─── kit_template ─────────────────────────────────────────────────────────────
//
// Pre-built package starting points — e.g. "Standard ALEXA 35 Narrative Kit".
// Anchored to a hero product (the camera body). From a DP's perspective these are
// the mental models you carry from house to house; the template is a starting list
// that the production coordinator then sources and prices out.

export const kitTemplate = pgTable("kit_template", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  anchorProductId: uuid("anchor_product_id").references(() => product.id),
  // shootType drives which accessories are suggested:
  // "narrative" = full matte box / follow focus / lenses set
  // "commercial" = same but shorter days, higher rate tolerance
  // "doc" = run-and-gun, lighter accessories
  // "episodic" = multi-cam, may add B-cam body
  // "music_video" = often gimbal / Steadicam add-ons
  shootType: text("shoot_type"),
  description: text("description"),
  isPublic: boolean("is_public").default(false),
  createdBy: uuid("created_by").references(() => users.id),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
})

export const kitTemplateItem = pgTable("kit_template_item", {
  id: uuid("id").primaryKey().defaultRandom(),
  kitTemplateId: uuid("kit_template_id").notNull().references(() => kitTemplate.id, { onDelete: "cascade" }),
  productId: uuid("product_id").notNull().references(() => product.id),
  quantity: integer("quantity").notNull().default(1),
  isRequired: boolean("is_required").default(true),   // false = "common add-on" prompt
  sortOrder: integer("sort_order").default(0),
  notes: text("notes"),
})

// ─── Productions layer enums ──────────────────────────────────────────────────

export const companyRoleEnum = pgEnum("company_role", ["owner", "admin", "member"])
export const productionRoleEnum = pgEnum("production_role", ["dp", "coordinator", "producer", "gaffer"])
export const productionStatusEnum = pgEnum("production_status", ["draft", "active", "wrapped", "archived"])
export const packageItemStatusEnum = pgEnum("package_item_status", [
  "draft",
  "sent",            // RFQ sent to rental houses
  "quote_received",  // ≥1 quote returned from a rental house
  "approved",        // quote selected and internally approved
  "confirmed",       // rental house confirmed the booking
  "unavailable",
  "over_budget",
])

// ─── users ────────────────────────────────────────────────────────────────────

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  // Better Auth required fields
  name: text("name").notNull().default(""),
  email: text("email").notNull().unique(),
  emailVerified: boolean("email_verified").notNull().default(false),
  image: text("image"),
  // App-specific fields
  fullName: text("full_name"),
  avatarUrl: text("avatar_url"),
  appRole: text("app_role").notNull().default("user"),
  experienceLevel: text("experience_level"),
  defaultProductionRole: productionRoleEnum("default_production_role"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
})

// ─── Better Auth tables ───────────────────────────────────────────────────────

export const session = pgTable("session", {
  id: text("id").primaryKey(),
  expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  token: text("token").notNull().unique(),
  ipAddress: text("ip_address"),
  userAgent: text("user_agent"),
  userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
})

export const account = pgTable("account", {
  id: text("id").primaryKey(),
  accountId: text("account_id").notNull(),
  providerId: text("provider_id").notNull(),
  userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  accessToken: text("access_token"),
  refreshToken: text("refresh_token"),
  idToken: text("id_token"),
  accessTokenExpiresAt: timestamp("access_token_expires_at", { withTimezone: true }),
  refreshTokenExpiresAt: timestamp("refresh_token_expires_at", { withTimezone: true }),
  scope: text("scope"),
  password: text("password"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
})

export const verification = pgTable("verification", {
  id: text("id").primaryKey(),
  identifier: text("identifier").notNull(),
  value: text("value").notNull(),
  expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
})

// ─── companies ────────────────────────────────────────────────────────────────

export const companies = pgTable("companies", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  slug: text("slug").unique(),
  logoUrl: text("logo_url"),
  billingEmail: text("billing_email"),
  plan: text("plan").notNull().default("free"),
  createdBy: uuid("created_by").notNull().references(() => users.id),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
})

// ─── company_members ──────────────────────────────────────────────────────────

export const companyMembers = pgTable(
  "company_members",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    companyId: uuid("company_id").notNull().references(() => companies.id, { onDelete: "cascade" }),
    userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
    role: companyRoleEnum("role").notNull(),
    invitedBy: uuid("invited_by").references(() => users.id),
    joinedAt: timestamp("joined_at", { withTimezone: true }),
  },
  (t) => [unique().on(t.companyId, t.userId)]
)

// ─── productions ──────────────────────────────────────────────────────────────

export const productions = pgTable("productions", {
  id: uuid("id").primaryKey().defaultRandom(),
  companyId: uuid("company_id").notNull().references(() => companies.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  shootType: text("shoot_type"),
  shootDays: integer("shoot_days"),
  startDate: date("start_date"),
  endDate: date("end_date"),
  totalBudget: numeric("total_budget", { precision: 12, scale: 2 }),
  status: productionStatusEnum("status").notNull().default("draft"),
  createdBy: uuid("created_by").notNull().references(() => users.id),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
})

// ─── production_members ───────────────────────────────────────────────────────

export const productionMembers = pgTable(
  "production_members",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    productionId: uuid("production_id").notNull().references(() => productions.id, { onDelete: "cascade" }),
    userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
    role: productionRoleEnum("role").notNull(),
    // Scopes a department-lead's (gaffer, etc.) authority to one department —
    // e.g. 'lighting_grip'. Null for dp/coordinator/producer, whose authority
    // isn't department-scoped.
    department: text("department"),
    invitedBy: uuid("invited_by").references(() => users.id),
    joinedAt: timestamp("joined_at", { withTimezone: true }),
  },
  (t) => [unique().on(t.productionId, t.userId)]
)

// ─── packages ─────────────────────────────────────────────────────────────────

export const packages = pgTable("packages", {
  id: uuid("id").primaryKey().defaultRandom(),
  productionId: uuid("production_id").notNull().references(() => productions.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  // If the package was seeded from a kit_template, track it for analytics
  // and to re-sync template updates later.
  sourceKitTemplateId: uuid("source_kit_template_id").references(() => kitTemplate.id),
  createdBy: uuid("created_by").references(() => users.id),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
})

// ─── package_items ────────────────────────────────────────────────────────────

export const packageItems = pgTable("package_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  packageId: uuid("package_id").notNull().references(() => packages.id, { onDelete: "cascade" }),
  gearId: uuid("gear_id").references(() => product.id),
  quantity: integer("quantity").notNull().default(1),
  // Settled day rate — populated when a quote is selected (is_selected = true).
  // Mirrors the selected package_item_quote.day_rate for quick read access.
  dayRateSnapshot: numeric("day_rate_snapshot", { precision: 10, scale: 2 }),
  status: packageItemStatusEnum("status").notNull().default("draft"),
  notes: text("notes"),
  addedBy: uuid("added_by").references(() => users.id),
  approvedBy: uuid("approved_by").references(() => users.id),
  approvedAt: timestamp("approved_at", { withTimezone: true }),
  sortOrder: integer("sort_order"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
})

// ─── invitations ──────────────────────────────────────────────────────────────

export const invitations = pgTable("invitations", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").notNull(),
  companyId: uuid("company_id").notNull().references(() => companies.id, { onDelete: "cascade" }),
  productionId: uuid("production_id").references(() => productions.id, { onDelete: "cascade" }),
  companyRole: companyRoleEnum("company_role"),
  productionRole: productionRoleEnum("production_role"),
  token: text("token").notNull().unique(),
  invitedBy: uuid("invited_by").references(() => users.id),
  expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  acceptedAt: timestamp("accepted_at", { withTimezone: true }),
})

// ─── rental_house ─────────────────────────────────────────────────────────────
//
// A company that rents out cinema equipment. Distinct from `brand` (manufacturer).
// Some companies appear in both — e.g. Panavision manufactures AND rents.
//
// Types:
//   full_service     = Keslow, AbelCine, Panavision — full camera packages + support
//   specialty        = Cine Visuals, Hot Rod Cameras — curated/niche inventory
//   peer_to_peer     = ShareGrid — individual owners renting their own gear
//   manufacturer     = ARRI rental program, Sony rental — direct from maker

export const rentalHouseTypeEnum = pgEnum("rental_house_type", [
  "full_service",
  "specialty",
  "peer_to_peer",
  "manufacturer",
])

export const rentalHouse = pgTable("rental_house", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  slug: text("slug").notNull().unique(),
  websiteUrl: text("website_url"),
  logoUrl: text("logo_url"),
  type: rentalHouseTypeEnum("type").notNull().default("full_service"),
  description: text("description"),
  // Optional link to brand table if the rental house is also a manufacturer
  // (e.g. Panavision, ARRI Rental)
  brandId: uuid("brand_id").references(() => brand.id),
  contactEmail: text("contact_email"),
  phone: text("phone"),
  isActive: boolean("is_active").default(true),
  scrapingEnabled: boolean("scraping_enabled").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
})

// ─── rental_house_location ────────────────────────────────────────────────────
//
// Physical locations for a rental house. Inventory and rates can vary by location
// (e.g. Keslow LA may have Panavision-grade glass that Keslow NY doesn't stock).
// Productions need to know which city they're pulling from.

export const rentalHouseLocation = pgTable("rental_house_location", {
  id: uuid("id").primaryKey().defaultRandom(),
  rentalHouseId: uuid("rental_house_id").notNull().references(() => rentalHouse.id, { onDelete: "cascade" }),
  city: text("city").notNull(),
  stateOrRegion: text("state_or_region"),
  country: text("country").notNull().default("US"),
  addressLine1: text("address_line_1"),
  phone: text("phone"),
  email: text("email"),
  contactEmail: text("contact_email"),
  isPrimary: boolean("is_primary").default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
})

// ─── rental_house_inventory ───────────────────────────────────────────────────
//
// Which products a rental house carries, with reference pricing and their
// internal product codes/URLs (useful for deep-linking and scraping).
//
// day_rate / week_rate are *reference* rates scraped from the house's website.
// Actual quoted rates live on package_item_quote — they may differ.
// week_rate is conventionally 3x the day rate but not always.
//
// locationId is optional: null means "available at all locations",
// a specific locationId means that SKU is location-specific.

export const rentalHouseInventory = pgTable(
  "rental_house_inventory",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    rentalHouseId: uuid("rental_house_id").notNull().references(() => rentalHouse.id, { onDelete: "cascade" }),
    productId: uuid("product_id").notNull().references(() => product.id, { onDelete: "cascade" }),
    locationId: uuid("location_id").references(() => rentalHouseLocation.id),
    dayRate: numeric("day_rate", { precision: 10, scale: 2 }),
    weekRate: numeric("week_rate", { precision: 10, scale: 2 }),
    // Rental house's own internal SKU or catalog number (useful for RFQ emails)
    rentalHouseProductCode: text("rental_house_product_code"),
    // Direct URL to the product on the rental house's website
    rentalHouseProductUrl: text("rental_house_product_url"),
    quantityOnHand: integer("quantity_on_hand"),
    isAvailable: boolean("is_available").default(true),
    lastScrapedAt: timestamp("last_scraped_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
  },
  (t) => [unique().on(t.rentalHouseId, t.productId, t.locationId)]
)

// ─── package_item_quote ───────────────────────────────────────────────────────
//
// When an RFQ is sent out, each rental house responds with a quote per item.
// Multiple quotes can exist per package_item — one per rental house contacted.
//
// Workflow:
//   1. Package item status moves to "sent" → quotes created (is_available = null)
//   2. Rental house replies → quotes updated with day_rate, is_available
//   3. Package item status moves to "quote_received"
//   4. User selects best quote (is_selected = true)
//   5. package_items.day_rate_snapshot is updated to match selected quote
//   6. Package item status moves to "approved" then "confirmed"
//
// A DP tip: always get at least 3 quotes. Rates for the same item can vary
// 15–30% between houses, especially for specialty glass and accessories.

export const packageItemQuote = pgTable("package_item_quote", {
  id: uuid("id").primaryKey().defaultRandom(),
  packageItemId: uuid("package_item_id").notNull().references(() => packageItems.id, { onDelete: "cascade" }),
  rentalHouseId: uuid("rental_house_id").notNull().references(() => rentalHouse.id),
  locationId: uuid("location_id").references(() => rentalHouseLocation.id),
  dayRate: numeric("day_rate", { precision: 10, scale: 2 }),
  weekRate: numeric("week_rate", { precision: 10, scale: 2 }),
  // null = awaiting reply, true = available, false = not available
  isAvailable: boolean("is_available"),
  isSelected: boolean("is_selected").default(false),
  // Free-form notes from the rental house (e.g. "available after Tue",
  // "substituting with ALEXA Mini LF S/N 12345")
  rentalHouseNotes: text("rental_house_notes"),
  quotedAt: timestamp("quoted_at", { withTimezone: true }),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
})

// ─── Relations ────────────────────────────────────────────────────────────────

export const brandRelations = relations(brand, ({ many }) => ({
  products: many(product),
  rentalHouses: many(rentalHouse),
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
  compatibilityValues: many(productCompatibilityValue),
  outgoingRelationships: many(productRelationship, { relationName: "sourceProduct" }),
  incomingRelationships: many(productRelationship, { relationName: "targetProduct" }),
  rentalInventory: many(rentalHouseInventory),
  kitTemplateItems: many(kitTemplateItem),
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

// Compatibility relations
export const compatibilityAxisRelations = relations(compatibilityAxis, ({ many }) => ({
  productValues: many(productCompatibilityValue),
}))

export const productCompatibilityValueRelations = relations(productCompatibilityValue, ({ one }) => ({
  product: one(product, { fields: [productCompatibilityValue.productId], references: [product.id] }),
  axis: one(compatibilityAxis, { fields: [productCompatibilityValue.axisId], references: [compatibilityAxis.id] }),
}))

export const productRelationshipRelations = relations(productRelationship, ({ one }) => ({
  sourceProduct: one(product, {
    fields: [productRelationship.sourceProductId],
    references: [product.id],
    relationName: "sourceProduct",
  }),
  targetProduct: one(product, {
    fields: [productRelationship.targetProductId],
    references: [product.id],
    relationName: "targetProduct",
  }),
}))

// Kit template relations
export const kitTemplateRelations = relations(kitTemplate, ({ one, many }) => ({
  anchorProduct: one(product, { fields: [kitTemplate.anchorProductId], references: [product.id] }),
  createdBy: one(users, { fields: [kitTemplate.createdBy], references: [users.id] }),
  items: many(kitTemplateItem),
  packages: many(packages),
}))

export const kitTemplateItemRelations = relations(kitTemplateItem, ({ one }) => ({
  template: one(kitTemplate, { fields: [kitTemplateItem.kitTemplateId], references: [kitTemplate.id] }),
  product: one(product, { fields: [kitTemplateItem.productId], references: [product.id] }),
}))

// Rental house relations
export const rentalHouseRelations = relations(rentalHouse, ({ one, many }) => ({
  brand: one(brand, { fields: [rentalHouse.brandId], references: [brand.id] }),
  locations: many(rentalHouseLocation),
  inventory: many(rentalHouseInventory),
  quotes: many(packageItemQuote),
}))

export const rentalHouseLocationRelations = relations(rentalHouseLocation, ({ one, many }) => ({
  rentalHouse: one(rentalHouse, { fields: [rentalHouseLocation.rentalHouseId], references: [rentalHouse.id] }),
  inventory: many(rentalHouseInventory),
  quotes: many(packageItemQuote),
}))

export const rentalHouseInventoryRelations = relations(rentalHouseInventory, ({ one }) => ({
  rentalHouse: one(rentalHouse, { fields: [rentalHouseInventory.rentalHouseId], references: [rentalHouse.id] }),
  product: one(product, { fields: [rentalHouseInventory.productId], references: [product.id] }),
  location: one(rentalHouseLocation, { fields: [rentalHouseInventory.locationId], references: [rentalHouseLocation.id] }),
}))

export const packageItemQuoteRelations = relations(packageItemQuote, ({ one }) => ({
  packageItem: one(packageItems, { fields: [packageItemQuote.packageItemId], references: [packageItems.id] }),
  rentalHouse: one(rentalHouse, { fields: [packageItemQuote.rentalHouseId], references: [rentalHouse.id] }),
  location: one(rentalHouseLocation, { fields: [packageItemQuote.locationId], references: [rentalHouseLocation.id] }),
}))

// Productions layer relations (unchanged from original)
export const usersRelations = relations(users, ({ many }) => ({
  companyMemberships: many(companyMembers),
  productionMemberships: many(productionMembers),
  ownedCompanies: many(companies),
  createdProductions: many(productions),
  createdKitTemplates: many(kitTemplate),
}))

export const companiesRelations = relations(companies, ({ one, many }) => ({
  createdBy: one(users, { fields: [companies.createdBy], references: [users.id] }),
  members: many(companyMembers),
  productions: many(productions),
}))

export const companyMembersRelations = relations(companyMembers, ({ one }) => ({
  company: one(companies, { fields: [companyMembers.companyId], references: [companies.id] }),
  user: one(users, { fields: [companyMembers.userId], references: [users.id] }),
}))

export const productionsRelations = relations(productions, ({ one, many }) => ({
  company: one(companies, { fields: [productions.companyId], references: [companies.id] }),
  createdBy: one(users, { fields: [productions.createdBy], references: [users.id] }),
  members: many(productionMembers),
  packages: many(packages),
}))

export const productionMembersRelations = relations(productionMembers, ({ one }) => ({
  production: one(productions, { fields: [productionMembers.productionId], references: [productions.id] }),
  user: one(users, { fields: [productionMembers.userId], references: [users.id] }),
}))

export const packagesRelations = relations(packages, ({ one, many }) => ({
  production: one(productions, { fields: [packages.productionId], references: [productions.id] }),
  sourceKitTemplate: one(kitTemplate, { fields: [packages.sourceKitTemplateId], references: [kitTemplate.id] }),
  createdBy: one(users, { fields: [packages.createdBy], references: [users.id] }),
  items: many(packageItems),
}))

export const packageItemsRelations = relations(packageItems, ({ one, many }) => ({
  package: one(packages, { fields: [packageItems.packageId], references: [packages.id] }),
  gear: one(product, { fields: [packageItems.gearId], references: [product.id] }),
  addedBy: one(users, { fields: [packageItems.addedBy], references: [users.id] }),
  approvedBy: one(users, { fields: [packageItems.approvedBy], references: [users.id] }),
  quotes: many(packageItemQuote),
}))

export const invitationsRelations = relations(invitations, ({ one }) => ({
  company: one(companies, { fields: [invitations.companyId], references: [companies.id] }),
  production: one(productions, { fields: [invitations.productionId], references: [productions.id] }),
  invitedBy: one(users, { fields: [invitations.invitedBy], references: [users.id] }),
}))

// ─── Types ────────────────────────────────────────────────────────────────────

export type Brand = typeof brand.$inferSelect
export type ProductCategory = typeof productCategory.$inferSelect
export type Product = typeof product.$inferSelect
export type ProductSpec = typeof productSpec.$inferSelect
export type SpecDefinition = typeof specDefinition.$inferSelect
export type SpecSection = typeof specSection.$inferSelect
export type ProductImage = typeof productImage.$inferSelect
export type User = typeof users.$inferSelect
export type Company = typeof companies.$inferSelect
export type CompanyMember = typeof companyMembers.$inferSelect
export type Production = typeof productions.$inferSelect
export type ProductionMember = typeof productionMembers.$inferSelect
export type Package = typeof packages.$inferSelect
export type PackageItem = typeof packageItems.$inferSelect
export type Invitation = typeof invitations.$inferSelect

// New types
export type CompatibilityAxis = typeof compatibilityAxis.$inferSelect
export type ProductCompatibilityValue = typeof productCompatibilityValue.$inferSelect
export type ProductRelationship = typeof productRelationship.$inferSelect
export type KitTemplate = typeof kitTemplate.$inferSelect
export type KitTemplateItem = typeof kitTemplateItem.$inferSelect
export type RentalHouse = typeof rentalHouse.$inferSelect
export type RentalHouseLocation = typeof rentalHouseLocation.$inferSelect
export type RentalHouseInventory = typeof rentalHouseInventory.$inferSelect
export type PackageItemQuote = typeof packageItemQuote.$inferSelect
