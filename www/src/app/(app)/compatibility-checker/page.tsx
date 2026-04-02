import { Suspense } from "react"
import { getProductsByCategory, checkCompatibility } from "@/lib/db/queries"
import { CompatibilityCheckerClient } from "./compatibility-checker-client"
import { Loader2 } from "lucide-react"

interface PageProps {
  searchParams: { camera?: string; lens?: string }
}

export const metadata = {
  title: "Compatibility Checker — Altoscope",
  description: "Check if your camera body and lens are compatible.",
}

export default async function CompatibilityCheckerPage({ searchParams }: PageProps) {
  const [cameras, lenses] = await Promise.all([
    getProductsByCategory("camera"),
    getProductsByCategory("lens"),
  ])

  const { camera: cameraSlug, lens: lensSlug } = searchParams

  const result =
    cameraSlug && lensSlug ? await checkCompatibility(cameraSlug, lensSlug) : null

  return (
    <div className="mx-auto max-w-4xl px-4 py-12 sm:px-6">
      <div className="mb-10">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">Compatibility Checker</h1>
        <p className="mt-2 text-muted-foreground">
          Select a camera body and a lens to see if they work together.
        </p>
      </div>

      <Suspense
        fallback={
          <div className="flex items-center gap-2 text-muted-foreground">
            <Loader2 className="h-4 w-4 animate-spin" />
            Loading gear database…
          </div>
        }
      >
        <CompatibilityCheckerClient
          cameras={cameras}
          lenses={lenses}
          initialCamera={cameraSlug}
          initialLens={lensSlug}
          result={result}
        />
      </Suspense>

      {/* DB connection proof */}
      <div className="mt-12 rounded-xl border bg-muted/30 p-6 text-sm">
        <p className="font-semibold">Database connection status</p>
        <p className="mt-1 text-muted-foreground">
          Loaded <strong>{cameras.length}</strong> cameras and{" "}
          <strong>{lenses.length}</strong> lenses from Supabase via Drizzle ORM.
        </p>
      </div>
    </div>
  )
}
