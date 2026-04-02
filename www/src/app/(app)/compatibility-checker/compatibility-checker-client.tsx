"use client"

import { useRouter, usePathname } from "next/navigation"
import { useTransition } from "react"
import type { ProductCard, CompatibilityResult } from "@/lib/db/queries"
import { CheckCircle, XCircle, HelpCircle, ArrowRight, Loader2 } from "lucide-react"
import { cn } from "@/lib/utils"

interface Props {
  cameras: ProductCard[]
  lenses: ProductCard[]
  initialCamera?: string
  initialLens?: string
  result: CompatibilityResult | null
}

export function CompatibilityCheckerClient({
  cameras,
  lenses,
  initialCamera = "",
  initialLens = "",
  result,
}: Props) {
  const router = useRouter()
  const pathname = usePathname()
  const [isPending, startTransition] = useTransition()

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const data = new FormData(e.currentTarget)
    const camera = data.get("camera") as string
    const lens = data.get("lens") as string
    if (!camera || !lens) return
    startTransition(() => {
      router.push(`${pathname}?camera=${camera}&lens=${lens}`)
    })
  }

  return (
    <div className="space-y-8">
      {/* Selector form */}
      <form onSubmit={handleSubmit} className="grid gap-6 sm:grid-cols-[1fr_auto_1fr_auto]">
        <div className="space-y-2">
          <label htmlFor="camera" className="block text-sm font-medium">
            Camera Body
          </label>
          <select
            id="camera"
            name="camera"
            defaultValue={initialCamera}
            className="w-full rounded-lg border bg-background px-3 py-2 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-ring"
          >
            <option value="">Select a camera…</option>
            {cameras.map((c) => (
              <option key={c.id} value={c.slug}>
                {c.fullName}
              </option>
            ))}
          </select>
        </div>

        <div className="flex items-end pb-2">
          <ArrowRight className="h-5 w-5 text-muted-foreground" />
        </div>

        <div className="space-y-2">
          <label htmlFor="lens" className="block text-sm font-medium">
            Lens
          </label>
          <select
            id="lens"
            name="lens"
            defaultValue={initialLens}
            className="w-full rounded-lg border bg-background px-3 py-2 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-ring"
          >
            <option value="">Select a lens…</option>
            {lenses.map((l) => (
              <option key={l.id} value={l.slug}>
                {l.fullName}
              </option>
            ))}
          </select>
        </div>

        <div className="flex items-end">
          <button
            type="submit"
            disabled={isPending}
            className="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-60"
          >
            {isPending && <Loader2 className="h-4 w-4 animate-spin" />}
            Check
          </button>
        </div>
      </form>

      {/* Result card */}
      {result && (
        <div
          className={cn(
            "rounded-xl border p-6 shadow-sm",
            result.compatible === true && "border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-950/30",
            result.compatible === false && "border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950/30",
            result.compatible === null && "border-yellow-200 bg-yellow-50 dark:border-yellow-800 dark:bg-yellow-950/30"
          )}
        >
          <div className="flex items-center gap-3">
            {result.compatible === true && (
              <CheckCircle className="h-6 w-6 flex-shrink-0 text-green-600" />
            )}
            {result.compatible === false && (
              <XCircle className="h-6 w-6 flex-shrink-0 text-red-600" />
            )}
            {result.compatible === null && (
              <HelpCircle className="h-6 w-6 flex-shrink-0 text-yellow-600" />
            )}
            <h2 className="text-lg font-semibold">
              {result.compatible === true && "Compatible"}
              {result.compatible === false && "Not directly compatible"}
              {result.compatible === null && "Unknown compatibility"}
            </h2>
          </div>

          <div className="mt-4 grid gap-4 sm:grid-cols-2">
            <SpecSummary
              label="Camera"
              name={result.camera.fullName}
              mount={result.camera.mountType}
              category={result.camera.categoryName}
            />
            <SpecSummary
              label="Lens"
              name={result.lens.fullName}
              mount={result.lens.mountType ?? result.lens.lensMount}
              category={result.lens.categoryName}
            />
          </div>

          {result.notes.length > 0 && (
            <ul className="mt-4 space-y-1">
              {result.notes.map((note, i) => (
                <li key={i} className="text-sm text-muted-foreground">
                  {note}
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      {!result && !isPending && (
        <div className="rounded-xl border border-dashed p-12 text-center text-muted-foreground">
          <HelpCircle className="mx-auto h-10 w-10 opacity-30" />
          <p className="mt-3 text-sm">Select a camera and lens above to check compatibility.</p>
        </div>
      )}
    </div>
  )
}

function SpecSummary({
  label,
  name,
  mount,
  category,
}: {
  label: string
  name: string
  mount: string | null | undefined
  category: string
}) {
  return (
    <div className="rounded-lg border bg-background/60 p-4">
      <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{label}</p>
      <p className="mt-1 font-semibold">{name}</p>
      <p className="text-sm text-muted-foreground">{category}</p>
      {mount && (
        <p className="mt-2 text-sm">
          <span className="font-medium">Mount:</span> {mount}
        </p>
      )}
    </div>
  )
}
