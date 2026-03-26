import { Suspense } from "react"
import Link from "next/link"
import Image from "next/image"
import { getProducts, getCategoriesWithCounts, type ProductCard } from "@/lib/db/queries"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import { GearFilters } from "./gear-filters"
import { Camera, ChevronRight } from "lucide-react"

// URL search params driven — no client state needed, works with Server Components
export default async function GearPage({
  searchParams,
}: {
  searchParams: { category?: string; q?: string }
}) {
  const { category, q } = searchParams

  const [products, categories] = await Promise.all([
    getProducts({ categorySlug: category, search: q }),
    getCategoriesWithCounts(),
  ])

  return (
    <div className="min-h-screen bg-background">
      {/* Nav */}
      <nav className="border-b border-border sticky top-0 z-10 bg-background/80 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-14 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <Camera className="h-6 w-6 text-primary" />
            <span className="font-bold text-lg">Altoscope</span>
          </Link>
          <div className="flex items-center gap-1 text-sm text-muted-foreground">
            <Link href="/" className="hover:text-foreground transition-colors">Home</Link>
            <ChevronRight className="h-3 w-3" />
            <span className="text-foreground">Gear</span>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-1">Gear Database</h1>
          <p className="text-muted-foreground">
            {products.length} {products.length === 1 ? "product" : "products"}
            {category ? ` in ${categories.find((c) => c.slug === category)?.name ?? category}` : " across all categories"}
            {q ? ` matching "${q}"` : ""}
          </p>
        </div>

        {/* Filters — client component for interactivity */}
        <GearFilters categories={categories} activeCategory={category} query={q} />

        {/* Grid */}
        <Suspense fallback={<ProductGridSkeleton />}>
          {products.length === 0 ? (
            <div className="py-24 text-center text-muted-foreground">
              No products found. Try adjusting your filters.
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 mt-6">
              {products.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          )}
        </Suspense>
      </div>
    </div>
  )
}

function ProductCard({ product: p }: { product: ProductCard }) {
  return (
    <Link href={`/gear/${p.slug}`} className="group block">
      <Card className="overflow-hidden border-border hover:border-primary/40 transition-colors h-full">
        {/* Image */}
        <div className="relative aspect-square bg-muted overflow-hidden">
          {p.primaryImageUrl ? (
            <Image
              src={p.primaryImageUrl}
              alt={p.fullName}
              fill
              className="object-contain p-3 group-hover:scale-105 transition-transform duration-300"
              sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 20vw"
            />
          ) : (
            <div className="absolute inset-0 flex items-center justify-center">
              <Camera className="h-10 w-10 text-muted-foreground/30" />
            </div>
          )}
        </div>

        <CardContent className="p-3">
          <p className="text-xs text-muted-foreground mb-0.5">{p.brandName}</p>
          <p className="text-sm font-medium leading-tight line-clamp-2 mb-2">{p.fullName}</p>
          <div className="flex items-center justify-between">
            <Badge variant="secondary" className="text-xs capitalize">
              {p.categoryName}
            </Badge>
            {p.msrpUsd && (
              <span className="text-xs text-muted-foreground">
                ${Number(p.msrpUsd).toLocaleString()}
              </span>
            )}
          </div>
        </CardContent>
      </Card>
    </Link>
  )
}

function ProductGridSkeleton() {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 mt-6">
      {Array.from({ length: 15 }).map((_, i) => (
        <div key={i} className="space-y-2">
          <Skeleton className="aspect-square w-full rounded-lg" />
          <Skeleton className="h-3 w-16" />
          <Skeleton className="h-4 w-full" />
        </div>
      ))}
    </div>
  )
}
