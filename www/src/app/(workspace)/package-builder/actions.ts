"use server"

import { addPackageItem, removePackageItem, updatePackageItemQty, addPackageComment } from "@/lib/db/queries"
import { getSession } from "@/lib/session"
import { revalidatePath } from "next/cache"

export async function addPackageItemAction(packageId: string, gearId: string) {
  const session = await getSession()
  if (!session) throw new Error("Not signed in.")

  const row = await addPackageItem(packageId, gearId, session.user.id)
  revalidatePath("/package-builder")
  return row
}

export async function updatePackageItemQtyAction(id: string, qty: number) {
  const session = await getSession()
  if (!session) throw new Error("Not signed in.")

  await updatePackageItemQty(id, qty)
  revalidatePath("/package-builder")
}

export async function removePackageItemAction(id: string) {
  const session = await getSession()
  if (!session) throw new Error("Not signed in.")

  await removePackageItem(id)
  revalidatePath("/package-builder")
}

export async function addPackageCommentAction(
  packageId: string,
  productionId: string,
  body: string,
  mentionedUserIds: string[]
) {
  const session = await getSession()
  if (!session) throw new Error("Not signed in.")
  if (!body.trim()) throw new Error("Comment can't be empty.")

  const comment = await addPackageComment(packageId, productionId, session.user.id, body.trim(), mentionedUserIds)
  revalidatePath("/package-builder")
  return {
    id: comment.id,
    createdAt: comment.createdAt.toISOString(),
    body: body.trim(),
    authorId: session.user.id,
    authorName: session.user.name,
    mentionedUserIds,
  }
}
