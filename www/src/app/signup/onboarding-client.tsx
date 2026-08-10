"use client"

import { useEffect, useRef, useState } from "react"
import Image from "next/image"
import { useRouter } from "next/navigation"
import {
  Video,
  Camera,
  Crosshair,
  Briefcase,
  ClipboardList,
  Lightbulb,
  Monitor,
  Building2,
  MoreHorizontal,
  Check,
  Package,
  MapPin,
  FileUp,
  UserCircle,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { FOCUS_RING, SELECTED_CARD_RING } from "@/components/elevation/shared"
import { Chip, Switch } from "@/components/elevation"
import type { OnboardingState } from "@/lib/db/queries"
import {
  WORKSPACE_OPTIONS,
  PROFESSION_OPTIONS,
  RATE_BAND_OPTIONS,
  UNION_STATUS_OPTIONS,
  KIT_CATEGORY_OPTIONS,
  INSURANCE_OPTIONS,
  type WorkspaceType,
} from "./constants"
import {
  saveWorkspaceStepAction,
  saveProfessionStepAction,
  saveWorkingDetailsStepAction,
  completeOnboardingAction,
} from "./actions"

// T0019 — 4 steps: Workspace → Profession → Working details → Ready.
// 2026-08-10: the original 5-step version (see git history) also had a
// "Set up your profile" step (name/home market/experience level/referral
// source) between Profession and Working details. Cut it — once "Complete
// your profile" on the Ready screen routes to a real profile page, a
// 2-field standalone step (home market + referral source, since name and
// experience level were also dropped) wasn't earning its place as a whole
// step. Those fields now live on the future profile page instead.
//
// Icons are lucide substitutes for the handoff's hand-drawn SVGs (this app
// already uses lucide everywhere else — Building2 in particular is the same
// icon already standing in for "rental house" elsewhere, kept consistent
// here) rather than porting each custom path 1:1.
const WORKSPACE_ICONS: Record<WorkspaceType, React.ReactNode> = {
  production: <Video size={30} strokeWidth={1.5} />,
  rental: <Building2 size={30} strokeWidth={1.5} />,
  hobbyist: <Camera size={30} strokeWidth={1.5} />,
}

const PROFESSION_ICONS: Record<string, React.ReactNode> = {
  dp: <Video size={17} strokeWidth={1.8} />,
  photographer: <Camera size={17} strokeWidth={1.8} />,
  videographer: <Video size={17} strokeWidth={1.8} />,
  ac: <Crosshair size={17} strokeWidth={1.8} />,
  producer: <Briefcase size={17} strokeWidth={1.8} />,
  coord: <ClipboardList size={17} strokeWidth={1.8} />,
  gaffer: <Lightbulb size={17} strokeWidth={1.8} />,
  dit: <Monitor size={17} strokeWidth={1.8} />,
  other: <MoreHorizontal size={17} strokeWidth={1.8} />,
}

const h1Class = "m-0 text-[28px] font-medium tracking-[-0.015em]"
const labelClass = "text-xs font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]"

function StepNav({
  onNext,
  onBack,
  onSkip,
  nextLabel = "Next",
  saving,
  disabled,
  sunset,
}: {
  onNext: () => void
  onBack?: () => void
  onSkip?: () => void
  nextLabel?: string
  saving?: boolean
  disabled?: boolean
  sunset?: boolean
}) {
  return (
    <div className="flex items-center gap-[14px]">
      <button
        type="button"
        onClick={onNext}
        disabled={saving || disabled}
        className={cn(
          "flex h-[42px] items-center justify-center rounded-[10px] border-none px-7 text-[13px] font-medium transition-opacity hover:opacity-90 disabled:cursor-default disabled:opacity-40",
          FOCUS_RING
        )}
        style={{
          background: sunset ? "var(--accent-sunset)" : "var(--interactive-default)",
          color: sunset ? "var(--accent-sunset-ink)" : "#fff",
        }}
      >
        {saving ? "Saving…" : nextLabel}
      </button>
      {onBack && (
        <button
          type="button"
          onClick={onBack}
          className="flex h-[42px] items-center rounded-[10px] border-none bg-transparent px-4 text-[13px] font-medium text-[var(--text-secondary)] hover:bg-white/[0.04]"
        >
          Back
        </button>
      )}
      {onSkip && (
        <button
          type="button"
          onClick={onSkip}
          className="flex h-[42px] items-center rounded-[10px] border-none bg-transparent px-4 text-[13px] font-medium text-[var(--text-muted)] hover:bg-white/[0.04]"
        >
          Skip
        </button>
      )}
    </div>
  )
}

function ChipRow({
  options,
  selected,
  onToggle,
}: {
  options: string[]
  selected: string[]
  onToggle: (value: string) => void
}) {
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((label) => (
        <Chip key={label} variant={selected.includes(label) ? "selected" : "default"} onClick={() => onToggle(label)}>
          {label}
        </Chip>
      ))}
    </div>
  )
}

// Session-scoped, not localStorage — a refresh mid-wizard shouldn't drop you
// back to step 1, but a genuinely new browser session/account should still
// start clean (2026-08-10, at Darin's request).
const STEP_STORAGE_KEY = "altoscope-signup-step"

export function OnboardingClient({ initialState }: { initialState: OnboardingState | null }) {
  const router = useRouter()
  const [step, setStep] = useState(1)
  const [saving, setSaving] = useState(false)

  // Runs once on mount, after the step-1 SSR/hydration render — jumping
  // straight to the saved step in the initializer instead would desync from
  // the server-rendered markup (window/sessionStorage don't exist during
  // SSR) and trigger a hydration mismatch.
  useEffect(() => {
    const saved = Number(sessionStorage.getItem(STEP_STORAGE_KEY))
    if (saved >= 1 && saved <= 4) setStep(saved)
  }, [])

  function goToStep(n: number) {
    setStep(n)
    sessionStorage.setItem(STEP_STORAGE_KEY, String(n))
  }
  const fileInputRef = useRef<HTMLInputElement>(null)

  const [workspaceType, setWorkspaceType] = useState<WorkspaceType | null>(initialState?.workspaceType ?? null)
  const [profession, setProfession] = useState<string | null>(initialState?.profession ?? null)
  const [rateBand, setRateBand] = useState<string[]>(initialState?.dayRateBand ? [initialState.dayRateBand] : [])
  const [unionStatus, setUnionStatus] = useState<string[]>(initialState?.unionStatus ? [initialState.unionStatus] : [])
  const [hasOwnerKit, setHasOwnerKit] = useState(initialState?.hasOwnerKit ?? false)
  const [kitCategories, setKitCategories] = useState<string[]>(initialState?.ownerKitCategories ?? [])
  const [insurance, setInsurance] = useState<string[]>(
    initialState?.insuranceStatus ? initialState.insuranceStatus.split(", ") : []
  )
  const [stubNotice, setStubNotice] = useState<string | null>(null)

  // "rental" skips the crew-specific steps entirely (Profession, Working
  // details — day rate/union/owner-kit/insurance don't apply to a business
  // account). "hobbyist" isn't selectable in the UI anymore but its rows
  // still exist in the DB, so it keeps the same skip behavior if reached.
  const isRental = workspaceType === "rental"
  const skipCrewSteps = isRental || workspaceType === "hobbyist"
  const completedRef = useRef(false)

  // Reaching "Ready" is what actually finishes onboarding — fires once, not
  // gated behind clicking an entry card (T0019: "Sets onboarding_completed_at").
  useEffect(() => {
    if (step === 4 && !completedRef.current) {
      completedRef.current = true
      completeOnboardingAction()
      sessionStorage.removeItem(STEP_STORAGE_KEY)
    }
  }, [step])

  function toggle(list: string[], setList: (v: string[]) => void, value: string, single: boolean) {
    if (single) {
      setList(list[0] === value ? [] : [value])
      return
    }
    setList(list.includes(value) ? list.filter((v) => v !== value) : [...list, value])
  }

  async function goNext() {
    setSaving(true)
    try {
      if (step === 1 && workspaceType) {
        await saveWorkspaceStepAction(workspaceType)
        goToStep(skipCrewSteps ? 4 : 2)
      } else if (step === 2) {
        await saveProfessionStepAction(profession)
        goToStep(3)
      } else if (step === 3) {
        await saveWorkingDetailsStepAction({
          dayRateBand: rateBand[0] ?? null,
          unionStatus: unionStatus[0] ?? null,
          hasOwnerKit,
          ownerKitCategories: kitCategories,
          insuranceStatus: insurance.length > 0 ? insurance.join(", ") : null,
        })
        goToStep(4)
      }
    } finally {
      setSaving(false)
    }
  }

  async function skipProfession() {
    setSaving(true)
    try {
      await saveProfessionStepAction(null)
      goToStep(3)
    } finally {
      setSaving(false)
    }
  }

  function goBack() {
    if (step === 4) {
      goToStep(skipCrewSteps ? 1 : 3)
      return
    }
    if (step > 1) goToStep(step - 1)
  }

  const workingDetailsComplete = rateBand.length > 0 && unionStatus.length > 0 && insurance.length > 0

  return (
    <div className="flex min-h-screen flex-col items-center bg-[var(--bg-base)] px-8 pb-7 pt-10 text-[var(--text-primary)]">
      <div className="flex items-center gap-[9px]">
        <Image src="/altoscope-mark-white.png" alt="" width={20} height={20} className="h-5 w-5 object-contain" />
        <span className="text-[15px] font-medium tracking-[-0.01em]">Altoscope</span>
      </div>

      {/* flex-1 + justify-center centers each step's content in the space
          left over below the logo — previously relied on a progress-dots row
          at the bottom (removed 2026-08-09) to balance the logo's mb-auto,
          so content had nothing pushing back up and sat pinned to the
          bottom. */}
      <div className="flex w-full max-w-[940px] flex-1 flex-col items-center justify-center py-12">
        {/* ── Step 1 · Workspace ────────────────────────────────────────── */}
        {step === 1 && (
          <div className="flex w-full flex-col items-center gap-7">
            <div className="flex flex-col items-center gap-2 text-center">
              <h1 className={h1Class}>Choose your workspace</h1>
              <p className="m-0 text-[13px] text-[var(--text-secondary)]">
                You can switch or join a second workspace later.
              </p>
            </div>
            <div className="grid w-full max-w-[640px] grid-cols-2 gap-4">
              {WORKSPACE_OPTIONS.map((opt) => {
                const selected = workspaceType === opt.value
                return (
                  <button
                    key={opt.value}
                    type="button"
                    onClick={() => setWorkspaceType(selected ? null : opt.value)}
                    className={cn(
                      "flex cursor-pointer flex-col items-center gap-[26px] rounded-2xl border-none px-6 pb-[30px] pt-8 text-center",
                      selected ? SELECTED_CARD_RING : "shadow-[var(--elevation-1)]",
                      FOCUS_RING
                    )}
                    style={{ background: selected ? "#3A3A42" : "var(--surface-02)" }}
                  >
                    <div
                      className="flex h-[104px] w-full flex-none items-center justify-center rounded-xl text-[var(--text-secondary)]"
                      style={{ background: "var(--surface-01)" }}
                    >
                      {WORKSPACE_ICONS[opt.value]}
                    </div>
                    <div className="flex flex-col gap-2">
                      <span className="text-[17px] font-medium">{opt.label}</span>
                      <span className="text-[13px] leading-[1.6] text-[var(--text-secondary)]">{opt.body}</span>
                    </div>
                  </button>
                )
              })}
            </div>
            <StepNav
              onNext={goNext}
              onBack={() => router.push("/")}
              nextLabel="Continue"
              saving={saving}
              disabled={!workspaceType}
            />
          </div>
        )}

        {/* ── Step 2 · Profession ───────────────────────────────────────── */}
        {step === 2 && !skipCrewSteps && (
          <div className="flex w-full flex-col gap-6">
            <div className="flex flex-col gap-1.5">
              <h1 className={h1Class}>What do you do?</h1>
              <p className="m-0 text-[13px] text-[var(--text-secondary)]">
                Choose the title that best describes you.
              </p>
            </div>
            <div className="grid grid-cols-5 gap-4">
              {PROFESSION_OPTIONS.map((opt) => {
                const selected = profession === opt.id
                return (
                  <button
                    key={opt.id}
                    type="button"
                    onClick={() => setProfession(selected ? null : opt.id)}
                    className={cn(
                      "flex min-h-[78px] cursor-pointer flex-col gap-2.5 rounded-[14px] border-none p-4 text-left",
                      selected ? SELECTED_CARD_RING : "shadow-[var(--elevation-1)]",
                      FOCUS_RING
                    )}
                    style={{
                      background: selected ? "#3A3A42" : "var(--surface-02)",
                      color: selected ? "var(--interactive-hover)" : "var(--text-secondary)",
                    }}
                  >
                    {PROFESSION_ICONS[opt.id]}
                    <span className="text-[13px] font-medium leading-[1.35] text-[var(--text-primary)]">
                      {opt.label}
                    </span>
                  </button>
                )
              })}
            </div>
            <StepNav onNext={goNext} onBack={goBack} onSkip={skipProfession} saving={saving} />
          </div>
        )}

        {/* ── Step 3 · Working details ──────────────────────────────────── */}
        {step === 3 && !skipCrewSteps && (
          <div className="flex w-full max-w-[620px] flex-col gap-[26px]">
            <div className="flex flex-col gap-1.5">
              <h1 className={h1Class}>A few working details</h1>
            </div>

            <div className="flex flex-col gap-2.5">
              <span className={labelClass}>Day rate band</span>
              <ChipRow
                options={RATE_BAND_OPTIONS}
                selected={rateBand}
                onToggle={(v) => toggle(rateBand, setRateBand, v, true)}
              />
            </div>

            <div className="flex flex-col gap-2.5">
              <span className={labelClass}>Union status</span>
              <ChipRow
                options={UNION_STATUS_OPTIONS}
                selected={unionStatus}
                onToggle={(v) => toggle(unionStatus, setUnionStatus, v, true)}
              />
            </div>

            <div className="flex flex-col gap-3 rounded-2xl p-[18px_20px] shadow-[var(--elevation-1)]" style={{ background: "#34343B" }}>
              <div className="flex items-center gap-4">
                <div className="flex flex-1 flex-col gap-0.5">
                  <span className="text-sm font-medium">I own gear I bring to jobs</span>
                  <span className="text-xs leading-[1.5] text-[var(--text-muted)]">
                    Owner-operator kit appears as a line item so rental houses don&apos;t double-quote it.
                  </span>
                </div>
                <Switch checked={hasOwnerKit} onChange={setHasOwnerKit} aria-label="I own gear I bring to jobs" />
              </div>
              {hasOwnerKit && (
                <div className="flex flex-wrap gap-2 pt-1">
                  {KIT_CATEGORY_OPTIONS.map((label) => (
                    <Chip
                      key={label}
                      variant={kitCategories.includes(label) ? "selected" : "default"}
                      onClick={() => toggle(kitCategories, setKitCategories, label, false)}
                    >
                      {label}
                    </Chip>
                  ))}
                </div>
              )}
            </div>

            <div className="flex flex-col gap-2.5">
              <span className={labelClass}>Insurance on file</span>
              <ChipRow
                options={INSURANCE_OPTIONS}
                selected={insurance}
                onToggle={(v) => toggle(insurance, setInsurance, v, false)}
              />
              <span className="text-[11px] text-[var(--text-muted)]">
                Certificates are uploaded later — rental houses only need them before pickup.
              </span>
            </div>

            <StepNav
              onNext={goNext}
              onBack={goBack}
              nextLabel="Finish setup ↗"
              sunset
              saving={saving}
              disabled={!workingDetailsComplete}
            />
          </div>
        )}

        {/* ── Step 4 · Ready ─────────────────────────────────────────────── */}
        {step === 4 && (
          <div className="flex w-full max-w-[720px] flex-col items-center gap-[30px] text-center">
            <div
              className="flex h-14 w-14 items-center justify-center rounded-2xl shadow-[var(--elevation-1)]"
              style={{ background: "#34343B" }}
            >
              <Check size={24} strokeWidth={2.2} color="var(--interactive-hover)" />
            </div>
            <div className="flex flex-col gap-2">
              <h1 className={h1Class}>Your workspace is ready</h1>
              <p className="m-0 text-[13px] leading-[1.6] text-[var(--text-secondary)]">
                Pick where to start. Everything else stays available from the sidebar.
              </p>
            </div>
            <div className="grid w-full grid-cols-4 gap-4">
              <EntryCard
                icon={<Package size={19} strokeWidth={1.8} />}
                title="Build a package"
                body="Start from a camera body."
                onClick={() => {
                  router.push("/package-builder")
                  router.refresh()
                }}
              />
              <EntryCard
                icon={<MapPin size={19} strokeWidth={1.8} />}
                title="Find rental houses"
                body="Browse houses in your market."
                onClick={() => {
                  router.push("/browse")
                  router.refresh()
                }}
              />
              <EntryCard
                icon={<FileUp size={19} strokeWidth={1.8} />}
                title="Import a gear list"
                body="CSV, XLSX, or a PDF quote."
                onClick={() => fileInputRef.current?.click()}
              />
              <EntryCard
                icon={<UserCircle size={19} strokeWidth={1.8} />}
                title="Complete your profile"
                body="Rates, credits, documents."
                onClick={() => {
                  router.push("/profile")
                  router.refresh()
                }}
              />
              <input
                ref={fileInputRef}
                type="file"
                accept=".csv,.xlsx,.pdf"
                className="hidden"
                onChange={() => setStubNotice("Gear list import isn't wired up yet — your file wasn't uploaded.")}
              />
            </div>
            {stubNotice && <p className="text-xs text-[var(--text-subtle)]">{stubNotice}</p>}
            <button
              type="button"
              onClick={goBack}
              className="flex h-[42px] items-center rounded-[10px] border-none bg-transparent px-4 text-[13px] font-medium text-[var(--text-secondary)] hover:bg-white/[0.04]"
            >
              Back
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

function EntryCard({
  icon,
  title,
  body,
  onClick,
}: {
  icon: React.ReactNode
  title: string
  body: string
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "flex flex-col gap-3 rounded-[14px] border-none p-4 text-left shadow-[var(--elevation-1)] transition-colors hover:bg-[var(--surface-02-hover)]",
        FOCUS_RING
      )}
      style={{ background: "#34343B" }}
    >
      <div
        className="flex h-[42px] w-[42px] items-center justify-center rounded-[11px] text-[var(--text-secondary)]"
        style={{ background: "var(--surface-01)" }}
      >
        {icon}
      </div>
      <div className="flex flex-col gap-0.5">
        <span className="text-[13px] font-medium">{title}</span>
        <span className="text-[11px] leading-[1.45] text-[var(--text-muted)]">{body}</span>
      </div>
    </button>
  )
}
