import { notFound } from "next/navigation"
import Link from "next/link"
import Image from "next/image"
import { getProductBySlug, type SpecRow } from "@/lib/db/queries"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { Camera, ChevronRight, ExternalLink } from "lucide-react"

export default async function ProductDetailPage({
  params,
}: {
  params: { slug: string }
}) {
  const { slug } = params
  const product = await getProductBySlug(slug)

  if (!product) notFound()

  // Group specs by section
  const sections = groupSpecsBySection(product.specs)

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
            <Link href="/gear" className="hover:text-foreground transition-colors">Gear</Link>
            <ChevronRight className="h-3 w-3" />
            <span className="text-foreground max-w-[180px] truncate">{product.model}</span>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        {/* Product header */}
        <div className="grid lg:grid-cols-[400px_1fr] gap-10 mb-12">
          {/* Image */}
          <div className="relative aspect-square bg-muted rounded-xl overflow-hidden">
            {product.primaryImageUrl ? (
              <Image
                src={product.primaryImageUrl}
                alt={product.fullName}
                fill
                className="object-contain p-8"
                sizes="(max-width: 1024px) 100vw, 400px"
                priority
              />
            ) : (
              <div className="absolute inset-0 flex items-center justify-center">
                <Camera className="h-20 w-20 text-muted-foreground/20" />
              </div>
            )}
          </div>

          {/* Info */}
          <div className="flex flex-col justify-center">
            <div className="flex items-center gap-2 mb-3">
              <Badge variant="secondary">{product.brandName}</Badge>
              <Badge variant="outline">{product.categoryName}</Badge>
            </div>
            <h1 className="text-3xl md:text-4xl font-bold mb-4">{product.fullName}</h1>

            {product.msrpUsd && (
              <p className="text-2xl font-semibold text-primary mb-6">
                ${Number(product.msrpUsd).toLocaleString()}
                <span className="text-base font-normal text-muted-foreground ml-1">MSRP</span>
              </p>
            )}

            {/* Key specs highlight (importance ≥ 8) */}
            {sections.length > 0 && (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-6">
                {product.specs
                  .filter((s) => (s.importance ?? 0) >= 8 && s.specValue)
                  .slice(0, 6)
                  .map((s) => (
                    <div key={s.normalizedKey} className="bg-muted/50 rounded-lg px-4 py-3">
                      <p className="text-xs text-muted-foreground mb-0.5">{s.displayName}</p>
                      <p className="text-sm font-medium">
                        {s.specValue}
                        {s.unitUsed && s.unitUsed !== "null" && ` ${s.unitUsed}`}
                      </p>
                    </div>
                  ))}
              </div>
            )}

            <div className="flex gap-3">
              {product.manufacturerUrl && (
                <Button variant="outline" size="sm" asChild>
                  <a href={product.manufacturerUrl} target="_blank" rel="noopener noreferrer">
                    <ExternalLink className="h-4 w-4 mr-1.5" />
                    Manufacturer Page
                  </a>
                </Button>
              )}
              <Button size="sm" asChild>
                <Link href="/gear">← Back to Gear</Link>
              </Button>
            </div>
          </div>
        </div>

        <Separator className="mb-10" />

        {/* Full spec table */}
        <h2 className="text-xl font-bold mb-6">Full Specifications</h2>

        {sections.length === 0 ? (
          <p className="text-muted-foreground">No specifications available yet.</p>
        ) : (
          <div className="space-y-8">
            {sections.map(({ sectionName, specs }) => (
              <div key={sectionName ?? "other"}>
                {sectionName && (
                  <h3 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-3">
                    {sectionName}
                  </h3>
                )}
                <div className="rounded-xl border border-border overflow-hidden">
                  <table className="w-full text-sm">
                    <tbody>
                      {specs.map((spec, i) => (
                        <tr
                          key={spec.normalizedKey}
                          className={i % 2 === 0 ? "bg-background" : "bg-muted/30"}
                        >
                          <td className="px-4 py-2.5 text-muted-foreground font-medium w-2/5 align-top">
                            {spec.displayName}
                          </td>
                          <td className="px-4 py-2.5 align-top">
                            {spec.specValue}
                            {spec.unitUsed && spec.unitUsed !== "null" && (
                              <span className="text-muted-foreground ml-1">{spec.unitUsed}</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

type SectionGroup = { sectionName: string | null; sectionOrder: number | null; specs: SpecRow[] }

function groupSpecsBySection(specs: SpecRow[]): SectionGroup[] {
  const map = new Map<string, SectionGroup>()

  for (const spec of specs) {
    if (!spec.specValue) continue
    const key = spec.sectionName ?? "__none__"
    if (!map.has(key)) {
      map.set(key, {
        sectionName: spec.sectionName,
        sectionOrder: spec.sectionOrder,
        specs: [],
      })
    }
    map.get(key)!.specs.push(spec)
  }

  return Array.from(map.values()).sort((a, b) => {
    const ao = a.sectionOrder ?? 999
    const bo = b.sectionOrder ?? 999
    return ao - bo
  })
}

// Static params for build-time generation (optional but fast for demos)
export async function generateStaticParams() {
  // Skip static generation — use dynamic rendering so data is always fresh
  return []
}
