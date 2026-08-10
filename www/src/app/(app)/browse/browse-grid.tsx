"use client"

import { useState, useTransition } from "react"
import Image from "next/image"
import { Check } from "lucide-react"
import { GearCard } from "@/components/elevation"
import { addPackageItemAction } from "@/app/(workspace)/package-builder/actions"

export interface BrowseGridProduct {
  id: string
  name: string
  spec: string
  imageUrl: string | null
  rate: number
  rateSource: "vendor" | "estimate"
}

// Client boundary kept as small as possible — everything else on /browse is
// server-rendered and URL-driven (T0020). Only the add-to-package button
// needs interactivity (a pending/added state per card).
export function BrowseGrid({
  products,
  packageId,
}: {
  products: BrowseGridProduct[]
  packageId: string | null
}) {
  return (
    <div className="grid grid-cols-2 gap-3.5 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
      {products.map((p) => (
        <BrowseCard key={p.id} product={p} packageId={packageId} />
      ))}
    </div>
  )
}

function BrowseCard({ product, packageId }: { product: BrowseGridProduct; packageId: string | null }) {
  const [state, setState] = useState<"idle" | "added" | "error">("idle")
  const [isPending, startTransition] = useTransition()

  function handleAdd() {
    if (!packageId || isPending) return
    startTransition(async () => {
      try {
        await addPackageItemAction(packageId, product.id)
        setState("added")
        setTimeout(() => setState("idle"), 1800)
      } catch (err) {
        console.error("Failed to add to package:", err)
        setState("error")
        setTimeout(() => setState("idle"), 1800)
      }
    })
  }

  return (
    <div className="relative">
      <GearCard
        photo={
          product.imageUrl ? (
            <Image src={product.imageUrl} alt={product.name} fill sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 20vw" />
          ) : undefined
        }
        name={product.name}
        spec={product.spec}
        rate={`$${product.rate.toLocaleString()}`}
        rateUnit={product.rateSource === "estimate" ? "/day est." : "/day"}
        onAdd={handleAdd}
        className={isPending ? "opacity-70" : undefined}
      />
      {state === "added" && (
        <div className="pointer-events-none absolute right-3 top-3 flex items-center gap-1 rounded-full bg-[var(--success-fill)] px-2 py-1 text-[10px] font-medium text-[var(--success-text)]">
          <Check size={11} strokeWidth={2.5} />
          Added
        </div>
      )}
      {state === "error" && (
        <div className="pointer-events-none absolute right-3 top-3 rounded-full bg-[var(--status-unavailable-bg)] px-2 py-1 text-[10px] font-medium text-[var(--status-unavailable-text)]">
          Failed
        </div>
      )}
    </div>
  )
}
