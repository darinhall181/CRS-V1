"use server"

import { addPackageItem, removePackageItem } from "@/lib/db/queries"
import { getSession } from "@/lib/session"
import { revalidatePath } from "next/cache"

export async function addPackageItemAction(packageId: string, gearId: string) {
  const session = await getSession()
  if (!session) throw new Error("Not signed in.")

  const row = await addPackageItem(packageId, gearId, session.user.id)
  revalidatePath("/package-builder")
  return row
}

export async function removePackageItemAction(id: string) {
  const session = await getSession()
  if (!session) throw new Error("Not signed in.")

  await removePackageItem(id)
  revalidatePath("/package-builder")
}
