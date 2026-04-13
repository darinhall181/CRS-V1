// Re-export DB-inferred types for use across the app
export type {
  Brand,
  ProductCategory,
  Product,
  ProductSpec,
  SpecDefinition,
  SpecSection,
  ProductImage,
} from "@/lib/db/schema"

// Re-export query result types
export type {
  ProductCard,
  ProductDetail,
  SpecRow,
  CategoryCount,
  CompatibilityResult,
} from "@/lib/db/queries"
