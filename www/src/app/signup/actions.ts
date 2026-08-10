"use server"

import { redirect } from "next/navigation"
import { getSession } from "@/lib/session"
import {
  setOnboardingWorkspace,
  setOnboardingProfession,
  setOnboardingProfile,
  setOnboardingWorkingDetails,
  completeOnboarding,
} from "@/lib/db/queries"
import { productionRoleForProfession, type WorkspaceType } from "./constants"

// T0019 — one server action per step, called as the wizard advances, not a
// single submit at the end. Abandoning mid-flow keeps whatever steps
// already landed (verified live — see task file).

async function requireUserId(): Promise<string> {
  const session = await getSession()
  if (!session) redirect("/login")
  return session.user.id
}

export async function saveWorkspaceStepAction(workspaceType: WorkspaceType) {
  const userId = await requireUserId()
  await setOnboardingWorkspace(userId, workspaceType)
}

export async function saveProfessionStepAction(professionId: string | null) {
  const userId = await requireUserId()
  await setOnboardingProfession(userId, professionId, productionRoleForProfession(professionId))
}

export async function saveProfileStepAction(fields: {
  name: string
  homeMarket: string | null
  experienceLevel: string | null
  referralSource: string | null
}) {
  const userId = await requireUserId()
  await setOnboardingProfile(userId, fields)
}

export async function saveWorkingDetailsStepAction(fields: {
  dayRateBand: string | null
  unionStatus: string | null
  hasOwnerKit: boolean
  ownerKitCategories: string[]
  insuranceStatus: string | null
}) {
  const userId = await requireUserId()
  await setOnboardingWorkingDetails(userId, fields)
}

export async function completeOnboardingAction() {
  const userId = await requireUserId()
  await completeOnboarding(userId)
}
