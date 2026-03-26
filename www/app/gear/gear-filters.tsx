"use client"

import { useRouter, usePathname } from "next/navigation"
import { useCallback, useTransition } from "react"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Search, X } from "lucide-react"
import { type CategoryCount } from "@/lib/db/queries"
import { cn } from "@/lib/utils"

interface GearFiltersProps {
  categories: CategoryCount[]
  activeCategory?: string
  query?: string
}

export function GearFilters({ categories, activeCategory, query }: GearFiltersProps) {
  const router = useRouter()
  const pathname = usePathname()
  const [isPending, startTransition] = useTransition()

  const navigate = useCallback(
    (params: Record<string, string | undefined>) => {
      const sp = new URLSearchParams()
      if (params.category) sp.set("category", params.category)
      if (params.q) sp.set("q", params.q)
      const qs = sp.toString()
      startTransition(() => {
        router.push(qs ? `${pathname}?${qs}` : pathname)
      })
    },
    [router, pathname]
  )

  const handleSearch = useCallback(
    (e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault()
      const fd = new FormData(e.currentTarget)
      navigate({ category: activeCategory, q: (fd.get("q") as string) || undefined })
    },
    [navigate, activeCategory]
  )

  return (
    <div className={cn("space-y-4", isPending && "opacity-60 pointer-events-none")}>
      {/* Search bar */}
      <form onSubmit={handleSearch} className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          name="q"
          defaultValue={query}
          placeholder="Search cameras, lenses…"
          className="pl-9 pr-10"
        />
        {query && (
          <button
            type="button"
            className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
            onClick={() => navigate({ category: activeCategory })}
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </form>

      {/* Category tabs */}
      <div className="flex flex-wrap gap-2">
        <Button
          variant={!activeCategory ? "default" : "outline"}
          size="sm"
          onClick={() => navigate({ q: query })}
        >
          All
        </Button>
        {categories.map((cat) => (
          <Button
            key={cat.slug}
            variant={activeCategory === cat.slug ? "default" : "outline"}
            size="sm"
            onClick={() => navigate({ category: cat.slug, q: query })}
          >
            {cat.name}
            <span className="ml-1.5 text-xs opacity-60">{cat.count}</span>
          </Button>
        ))}
      </div>
    </div>
  )
}
