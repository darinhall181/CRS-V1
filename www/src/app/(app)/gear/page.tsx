import { getProducts, getCategoriesWithCounts } from "@/lib/db/queries"
import Image from "next/image"
import Link from "next/link"

export const dynamic = "force-dynamic"

export const metadata = {
  title: "Gear — Altoscope",
  description: "Browse all cameras and lenses in the Altoscope database.",
}

interface PageProps {
  searchParams: { category?: string }
}

export default async function GearPage({ searchParams }: PageProps) {
  const [products, categories] = await Promise.all([
    getProducts({ categorySlug: searchParams.category, limit: 100 }),
    getCategoriesWithCounts(),
  ])

  return (
    <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">Gear Database</h1>
        <p className="mt-2 text-muted-foreground">
          {products.length} products across {categories.length} categories
        </p>
      </div>

      {/* Category filter */}
      <div className="mb-8 flex flex-wrap gap-2">
        <Link
          href="/gear"
          className={`rounded-full border px-3 py-1 text-sm transition-colors hover:bg-accent ${
            !searchParams.category ? "bg-primary text-primary-foreground border-primary" : ""
          }`}
        >
          All
        </Link>
        {categories.map((cat) => (
          <Link
            key={cat.slug}
            href={`/gear?category=${cat.slug}`}
            className={`rounded-full border px-3 py-1 text-sm transition-colors hover:bg-accent ${
              searchParams.category === cat.slug
                ? "bg-primary text-primary-foreground border-primary"
                : ""
            }`}
          >
            {cat.name} <span className="text-muted-foreground">({cat.count})</span>
          </Link>
        ))}
      </div>

      {/* Product grid */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {products.map((p) => (
          <div
            key={p.id}
            className="group rounded-xl border bg-card shadow-sm transition-shadow hover:shadow-md"
          >
            <div className="relative aspect-square overflow-hidden rounded-t-xl bg-muted">
              {p.primaryImageUrl ? (
                <Image
                  src={p.primaryImageUrl}
                  alt={p.fullName}
                  fill
                  className="object-contain p-4 transition-transform group-hover:scale-105"
                  sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                />
              ) : (
                <div className="flex h-full items-center justify-center text-muted-foreground text-xs">
                  No image
                </div>
              )}
            </div>
            <div className="p-4">
              <p className="text-xs text-muted-foreground">{p.brandName} · {p.categoryName}</p>
              <p className="mt-1 font-medium leading-snug">{p.fullName}</p>
              {p.msrpUsd && (
                <p className="mt-1 text-sm text-muted-foreground">${Number(p.msrpUsd).toLocaleString()}</p>
              )}
            </div>
          </div>
        ))}
      </div>

      {products.length === 0 && (
        <div className="py-20 text-center text-muted-foreground">
          No products found for this category.
        </div>
      )}
    </div>
  )
}
