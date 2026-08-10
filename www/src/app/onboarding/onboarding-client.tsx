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
import { Chip, SegmentedToggle, Switch } from "@/components/elevation"
import type { OnboardingState } from "@/lib/db/queries"
import {
  WORKSPACE_OPTIONS,
  PROFESSION_OPTIONS,
  HOME_MARKET_OPTIONS,
  EXPERIENCE_LEVELS,
  RATE_BAND_OPTIONS,
  UNION_STATUS_OPTIONS,
  KIT_CATEGORY_OPTIONS,
  INSURANCE_OPTIONS,
  type WorkspaceType,
} from "./constants"
import {
  saveWorkspaceStepAction,
  saveProfessionStepAction,
  saveProfileStepAction,
  saveWorkingDetailsStepAction,
  completeOnboardingAction,
} from "./actions"

// T0019 — steps 1–5 of Onboarding.dc.html. Icons are lucide substitutes for
// the handoff's hand-drawn SVGs (this app already uses lucide everywhere
// else — Building2 in particular is the same icon already standing in for
// "rental house" elsewhere, kept consistent here) rather than porting each
// custom path 1:1. Colors/spacing/copy otherwise match the handoff.
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
  rental: <Building2 size={17} strokeWidth={1.8} />,
  other: <MoreHorizontal size={17} strokeWidth={1.8} />,
}

const STEP_LABELS = ["Workspace", "Profession", "Profile", "Working details", "Ready"]

const h1Class = "m-0 text-[28px] font-medium tracking-[-0.015em]"
const labelClass = "text-xs font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]"
const inputClass = cn(
  "h-11 rounded-[10px] border-none bg-[var(--surface-01)] px-3.5 text-[13px] text-[var(--text-primary)] shadow-[inset_0_2px_5px_rgba(0,0,0,0.30)] placeholder:text-[var(--text-subtle)]",
  FOCUS_RING
)

function StepNav({
  onNext,
  onBack,
  onSkip,
  nextLabel = "Next",
  saving,
  sunset,
}: {
  onNext: () => void
  onBack?: () => void
  onSkip?: () => void
  nextLabel?: string
  saving?: boolean
  sunset?: boolean
}) {
  return (
    <div className="flex items-center gap-[14px]">
      <button
        type="button"
        onClick={onNext}
        disabled={saving}
        className={cn(
          "flex h-[42px] items-center justify-center rounded-[10px] border-none px-7 text-[13px] font-medium transition-opacity hover:opacity-90 disabled:cursor-default disabled:opacity-60",
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

export function OnboardingClient({
  initialState,
  userName,
}: {
  initialState: OnboardingState | null
  userName: string
}) {
  const router = useRouter()
  const [step, setStep] = useState(1)
  const [saving, setSaving] = useState(false)

  const [workspaceType, setWorkspaceType] = useState<WorkspaceType>(initialState?.workspaceType ?? "production")
  const [profession, setProfession] = useState<string | null>(initialState?.profession ?? null)
  const [name, setName] = useState(initialState?.name || userName)
  const [homeMarket, setHomeMarket] = useState(initialState?.homeMarket ?? HOME_MARKET_OPTIONS[0])
  const [experienceLevel, setExperienceLevel] = useState(initialState?.experienceLevel ?? "Standard")
  const [referralSource, setReferralSource] = useState(initialState?.referralSource ?? "")
  const [rateBand, setRateBand] = useState<string[]>(initialState?.dayRateBand ? [initialState.dayRateBand] : [])
  const [unionStatus, setUnionStatus] = useState<string[]>(initialState?.unionStatus ? [initialState.unionStatus] : [])
  const [hasOwnerKit, setHasOwnerKit] = useState(initialState?.hasOwnerKit ?? false)
  const [kitCategories, setKitCategories] = useState<string[]>(initialState?.ownerKitCategories ?? [])
  const [insurance, setInsurance] = useState<string[]>(
    initialState?.insuranceStatus ? initialState.insuranceStatus.split(", ") : []
  )
  const [stubNotice, setStubNotice] = useState<string | null>(null)

  const isHobbyist = workspaceType === "hobbyist"
  const completedRef = useRef(false)

  // Reaching "Ready" is what actually finishes onboarding — fires once, not
  // gated behind clicking an entry card (T0019: "Sets onboarding_completed_at").
  useEffect(() => {
    if (step === 5 && !completedRef.current) {
      completedRef.current = true
      completeOnboardingAction()
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
      if (step === 1) {
        await saveWorkspaceStepAction(workspaceType)
        setStep(2)
      } else if (step === 2) {
        await saveProfessionStepAction(profession)
        setStep(3)
      } else if (step === 3) {
        await saveProfileStepAction({
          name: name.trim() || userName,
          homeMarket,
          experienceLevel,
          referralSource: referralSource.trim() || null,
        })
        setStep(isHobbyist ? 5 : 4)
      } else if (step === 4) {
        await saveWorkingDetailsStepAction({
          dayRateBand: rateBand[0] ?? null,
          unionStatus: unionStatus[0] ?? null,
          hasOwnerKit,
          ownerKitCategories: kitCategories,
          insuranceStatus: insurance.length > 0 ? insurance.join(", ") : null,
        })
        setStep(5)
      }
    } finally {
      setSaving(false)
    }
  }

  async function skipProfession() {
    setSaving(true)
    try {
      await saveProfessionStepAction(null)
      setStep(3)
    } finally {
      setSaving(false)
    }
  }

  async function skipWorkingDetails() {
    setSaving(true)
    try {
      await saveWorkingDetailsStepAction({
        dayRateBand: null,
        unionStatus: null,
        hasOwnerKit: false,
        ownerKitCategories: [],
        insuranceStatus: null,
      })
      setStep(5)
    } finally {
      setSaving(false)
    }
  }

  function goBack() {
    if (step === 5) setStep(isHobbyist ? 3 : 4)
    else if (step > 1) setStep((s) => s - 1)
  }

  const dots = STEP_LABELS.map((label, i) => ({ label, step: i + 1 })).filter((d) => !(isHobbyist && d.step === 4))

  return (
    <div className="flex min-h-screen flex-col items-center bg-[var(--bg-base)] px-8 pb-7 pt-10 text-[var(--text-primary)]">
      <div className="mb-auto flex items-center gap-[9px]">
        <Image src="/altoscope-mark-white.png" alt="" width={20} height={20} className="h-5 w-5 object-contain" />
        <span className="text-[15px] font-medium tracking-[-0.01em]">Altoscope</span>
      </div>

      <div className="flex w-full max-w-[940px] flex-col items-center py-12">
        {/* ── Step 1 · Workspace ────────────────────────────────────────── */}
        {step === 1 && (
          <div className="flex w-full flex-col items-center gap-7">
            <div className="flex flex-col items-center gap-2 text-center">
              <h1 className={h1Class}>Choose your workspace</h1>
              <p className="m-0 text-[13px] text-[var(--text-secondary)]">
                You can switch or join a second workspace later.
              </p>
            </div>
            <div className="grid w-full grid-cols-3 gap-4">
              {WORKSPACE_OPTIONS.map((opt) => {
                const selected = workspaceType === opt.value
                return (
                  <button
                    key={opt.value}
                    type="button"
                    onClick={() => setWorkspaceType(opt.value)}
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
            <StepNav onNext={goNext} nextLabel="Continue" saving={saving} />
          </div>
        )}

        {/* ── Step 2 · Profession ───────────────────────────────────────── */}
        {step === 2 && (
          <div className="flex w-full flex-col gap-6">
            <div className="flex flex-col gap-1.5">
              <h1 className={h1Class}>What do you do?</h1>
              <p className="m-0 text-[13px] text-[var(--text-secondary)]">
                Sets your default gear categories and rate references.
              </p>
            </div>
            <div className="grid grid-cols-5 gap-4">
              {PROFESSION_OPTIONS.map((opt) => {
                const selected = profession === opt.id
                return (
                  <button
                    key={opt.id}
                    type="button"
                    onClick={() => setProfession(opt.id)}
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

        {/* ── Step 3 · Profile ──────────────────────────────────────────── */}
        {step === 3 && (
          <div className="flex w-full max-w-[460px] flex-col gap-[22px]">
            <h1 className={h1Class}>Set up your profile</h1>

            <div className="flex flex-col gap-[7px]">
              <label className={labelClass}>Name</label>
              <input value={name} onChange={(e) => setName(e.target.value)} className={inputClass} />
            </div>

            <div className="flex flex-col gap-[7px]">
              <label className={labelClass}>Home market</label>
              <select
                value={homeMarket}
                onChange={(e) => setHomeMarket(e.target.value)}
                className={cn(inputClass, "appearance-none")}
              >
                {HOME_MARKET_OPTIONS.map((m) => (
                  <option key={m} value={m}>
                    {m}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex flex-col gap-[7px]">
              <label className={labelClass}>Experience level</label>
              <SegmentedToggle
                options={EXPERIENCE_LEVELS}
                value={EXPERIENCE_LEVELS.indexOf(experienceLevel as (typeof EXPERIENCE_LEVELS)[number])}
                onChange={(i) => setExperienceLevel(EXPERIENCE_LEVELS[i])}
                width={432}
                height={44}
                aria-label="Experience level"
              />
              <span className="text-[11px] leading-[1.5] text-[var(--text-muted)]">
                Changes defaults and how much detail is shown. Adjustable anytime in settings.
              </span>
            </div>

            <div className="flex flex-col gap-[7px]">
              <label className={labelClass}>
                How did you hear about us? <span className="normal-case tracking-normal text-[var(--text-subtle)]">(optional)</span>
              </label>
              <input
                value={referralSource}
                onChange={(e) => setReferralSource(e.target.value)}
                placeholder="A rental house, a colleague, a set…"
                className={inputClass}
              />
            </div>

            <div className="mt-1">
              <StepNav onNext={goNext} onBack={goBack} saving={saving} />
            </div>
          </div>
        )}

        {/* ── Step 4 · Working details ──────────────────────────────────── */}
        {step === 4 && !isHobbyist && (
          <div className="flex w-full max-w-[620px] flex-col gap-[26px]">
            <div className="flex flex-col gap-1.5">
              <h1 className={h1Class}>A few working details</h1>
              <p className="m-0 text-[13px] leading-[1.6] text-[var(--text-secondary)]">
                All optional. Rate cards, credits, and documents can be filled in later from profile settings.
              </p>
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

            <StepNav onNext={goNext} onBack={goBack} onSkip={skipWorkingDetails} nextLabel="Finish setup ↗" sunset saving={saving} />
          </div>
        )}

        {/* ── Step 5 · Ready ─────────────────────────────────────────────── */}
        {step === 5 && (
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
                onClick={() => router.push("/package-builder")}
              />
              <EntryCard
                icon={<MapPin size={19} strokeWidth={1.8} />}
                title="Find rental houses"
                body="Browse houses in your market."
                onClick={() => setStubNotice("Rental house map is coming soon.")}
              />
              <EntryCard
                icon={<FileUp size={19} strokeWidth={1.8} />}
                title="Import a gear list"
                body="CSV, XLSX, or a PDF quote."
                onClick={() => setStubNotice("Gear list import is coming soon.")}
              />
              <EntryCard
                icon={<UserCircle size={19} strokeWidth={1.8} />}
                title="Complete your profile"
                body="Rates, credits, documents."
                onClick={() => setStubNotice("Full profile settings are coming soon.")}
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

      <div className="mt-auto flex h-5 items-center gap-2">
        {dots.map((d) => (
          <button
            key={d.step}
            type="button"
            title={d.label}
            onClick={() => setStep(d.step)}
            className="h-1 rounded-full transition-all"
            style={{
              width: d.step === step ? 20 : 8,
              background: d.step === step ? "#F4F4F5" : "rgba(255,255,255,0.22)",
            }}
          />
        ))}
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
