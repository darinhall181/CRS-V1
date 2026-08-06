"use server"

import { addPackageItem, removePackageItem } from "@/lib/db/queries"
import { revalidatePath } from "next/cache"

// Hardcoded until real session reading exists (see docs/tasks/T0007) — same
// shim pattern as DEMO_PRODUCTION_ID in page.tsx.
const DEMO_USER_ID = "5407eb4f-7d60-4b28-bd36-5b62187e9b50"

export async function addPackageItemAction(packageId: string, gearId: string) {
  const row = await addPackageItem(packageId, gearId, DEMO_USER_ID)
  revalidatePath("/package-builder")
  return row
}

export async function removePackageItemAction(id: string) {
  await removePackageItem(id)
  revalidatePath("/package-builder")
}
