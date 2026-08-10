"use client"

import { useState } from "react"
import Image from "next/image"
import Link from "next/link"
import { ArrowLeft } from "lucide-react"
import { useRouter, useSearchParams } from "next/navigation"
import { authClient } from "@/lib/auth-client"
import { FOCUS_RING } from "@/components/elevation/shared"
import { cn } from "@/lib/utils"

// T0018 — default auth page, not just first-run onboarding: every sign-in
// renders this split screen, per Darin's 2026-08-08 decision. This is step 0
// ("· Log in") of the real onboarding handoff (Onboarding.dc.html), matched
// pixel-for-pixel where the handoff specifies it (colors, sizes, copy) —
// steps 1–5 (workspace/role/profile/etc.) are T0019's, not built here.
//
// Google OAuth wired 2026-08-10 once Darin had real Console credentials in
// www/.env.local (GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET) — see auth.ts's
// socialProviders.google. A brand-new Google identity gets a user row the
// same way email/password signup does, so it lands in /signup (T0019's
// onboarding wizard) same as everyone else, no extra plumbing needed there.
export default function LoginPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const next = searchParams.get("next") || "/dashboard"

  // Visiting /signup while signed out bounces here via middleware as
  // /login?next=%2Fsignup (it's the gated onboarding-wizard route, T0019) —
  // land straight on the create-account form in that case instead of
  // sign-in, since hitting /signup is a declaration of "I want an account."
  const [mode, setMode] = useState<"sign-in" | "sign-up">(next === "/signup" ? "sign-up" : "sign-in")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [name, setName] = useState("")
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [googleLoading, setGoogleLoading] = useState(false)
  const [showForgotNotice, setShowForgotNotice] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const { error: authError } =
      mode === "sign-in"
        ? await authClient.signIn.email({ email, password })
        : await authClient.signUp.email({ email, password, name: name || email })

    setLoading(false)

    if (authError) {
      setError(authError.message ?? "Something went wrong — check your details and try again.")
      return
    }

    router.push(next)
    router.refresh()
  }

  async function handleGoogleSignIn() {
    setError(null)
    setGoogleLoading(true)
    const { error: authError } = await authClient.signIn.social({ provider: "google", callbackURL: next })
    if (authError) {
      setGoogleLoading(false)
      setError(authError.message ?? "Google sign-in failed — try again or use email below.")
    }
    // No else branch — on success Better Auth redirects the browser to
    // Google itself, so there's nothing to navigate to here.
  }

  const inputClass = cn(
    "h-11 rounded-[10px] border-none bg-[var(--surface-01)] px-3.5 text-[13px] text-[var(--text-primary)] shadow-[inset_0_2px_5px_rgba(0,0,0,0.30)] placeholder:text-[var(--text-subtle)]",
    FOCUS_RING
  )
  const labelClass = "text-xs font-medium uppercase tracking-[0.04em] text-[var(--text-muted)]"

  return (
    <div className="grid min-h-screen bg-[var(--bg-base)] text-[var(--text-primary)] lg:grid-cols-2 lg:gap-5 lg:p-5">
      {/* ── Brand panel ─────────────────────────────────────────────────── */}
      {/* 2026-08-10, at Darin's request: same dark panel as before, but as an
          inset rounded-2xl card (matching the onboarding wizard's card
          radius) instead of flush full-bleed — the light-panel version this
          replaced didn't land, but the card treatment itself did. */}
      <div
        className="hidden flex-col justify-center gap-[26px] rounded-2xl px-[72px] py-16 lg:flex"
        style={{ background: "var(--surface-page-shell)" }}
      >
        <Image
          src="/altoscope-mark-white.png"
          alt="Altoscope"
          width={44}
          height={44}
          className="h-11 w-auto self-start object-contain"
        />
        <h2 className="m-0 max-w-[420px] text-[34px] font-light leading-[1.25] tracking-[-0.015em]">
          Every gear list, budget, and quote in one place.
        </h2>
        <p className="m-0 max-w-[380px] text-[13px] leading-[1.7] text-[var(--text-secondary)]">
          Build a package that&apos;s checked for compatibility, priced against your budget, and
          ready to send to a rental house.
        </p>
      </div>

      {/* ── Auth card ────────────────────────────────────────────────────── */}
      <div className="relative flex flex-col items-center justify-center px-8 py-16">
        {/* 2026-08-10, at Darin's request — the landing page (marketing waitlist,
            "/") doesn't have a way back in yet either, so this is the first leg
            of that connection: Home here, and a "Log in" link added to the
            marketing nav pointing back at /login. */}
        <Link
          href="/"
          className={cn(
            "absolute left-8 top-8 flex items-center gap-[7px] text-[13px] font-medium text-[var(--text-secondary)] transition-colors hover:text-[var(--text-primary)]",
            FOCUS_RING
          )}
        >
          <ArrowLeft size={15} strokeWidth={1.8} />
          Home
        </Link>

        <div className="flex w-full max-w-[360px] flex-col gap-5">
          <div className="flex flex-col items-center gap-1.5 text-center">
            <h1 className="m-0 text-[26px] font-medium tracking-[-0.015em]">
              {mode === "sign-in" ? "Log in to Altoscope" : "Create your account"}
            </h1>
            <p className="m-0 text-xs text-[var(--text-muted)]">
              An account is required to browse gear and rental houses.
            </p>
          </div>

          <button
            type="button"
            onClick={handleGoogleSignIn}
            disabled={googleLoading}
            className={cn(
              "flex h-[46px] items-center justify-center gap-2.5 rounded-[10px] border-none text-[13px] font-medium shadow-[0_1px_3px_rgba(0,0,0,0.35),0_6px_18px_rgba(0,0,0,0.26)] transition-colors hover:bg-[#3A3A42] disabled:cursor-default disabled:opacity-60",
              FOCUS_RING
            )}
            style={{ background: "#34343B", color: "var(--text-primary)" }}
          >
            <GoogleIcon />
            {googleLoading ? "Redirecting…" : "Continue with Google"}
          </button>

          <div className="flex items-center gap-3.5">
            <span className="h-px flex-1" style={{ background: "rgba(255,255,255,0.10)" }} />
            <span className="text-[11px] text-[var(--text-muted)]">or continue with email</span>
            <span className="h-px flex-1" style={{ background: "rgba(255,255,255,0.10)" }} />
          </div>

          <form onSubmit={handleSubmit} className="flex flex-col gap-5">
            {mode === "sign-up" && (
              <div className="flex flex-col gap-[7px]">
                <label htmlFor="name" className={labelClass}>
                  Name
                </label>
                <input
                  id="name"
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  autoComplete="name"
                  placeholder="Elena Vasquez"
                  className={inputClass}
                />
              </div>
            )}

            <div className="flex flex-col gap-[7px]">
              <label htmlFor="email" className={labelClass}>
                Email
              </label>
              <input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
                placeholder="you@production.co"
                className={inputClass}
              />
            </div>

            <div className="flex flex-col gap-[7px]">
              <div className="flex items-baseline justify-between">
                <label htmlFor="password" className={labelClass}>
                  Password
                </label>
                {mode === "sign-in" && (
                  <button
                    type="button"
                    onClick={() => setShowForgotNotice(true)}
                    className="text-[11px] text-[var(--interactive-default)] hover:text-[var(--interactive-hover)]"
                  >
                    Forgot password?
                  </button>
                )}
              </div>
              <input
                id="password"
                type="password"
                required
                minLength={8}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete={mode === "sign-in" ? "current-password" : "new-password"}
                placeholder="8 characters minimum"
                className={inputClass}
              />
              {mode === "sign-in" && showForgotNotice && (
                <p className="text-[11px] text-[var(--text-subtle)]">
                  Password reset isn&apos;t set up yet — contact your workspace admin for now.
                </p>
              )}
            </div>

            {error && <p className="text-xs" style={{ color: "var(--danger-text)" }}>{error}</p>}

            <button
              type="submit"
              disabled={loading}
              className={cn(
                "flex h-[46px] items-center justify-center rounded-[10px] border-none text-[13px] font-medium text-white transition-colors hover:bg-[var(--interactive-hover)] disabled:cursor-default disabled:opacity-60",
                FOCUS_RING
              )}
              style={{ background: "var(--interactive-default)" }}
            >
              {loading ? "Please wait…" : mode === "sign-in" ? "Log in" : "Create account"}
            </button>
          </form>

          <div className="text-center text-xs text-[var(--text-muted)]">
            {mode === "sign-in" ? (
              <>
                New to Altoscope?{" "}
                <button
                  type="button"
                  onClick={() => {
                    setMode("sign-up")
                    setError(null)
                    setShowForgotNotice(false)
                  }}
                  className="text-[var(--interactive-default)] hover:text-[var(--interactive-hover)]"
                >
                  Create an account
                </button>
              </>
            ) : (
              <>
                Already have an account?{" "}
                <button
                  type="button"
                  onClick={() => {
                    setMode("sign-in")
                    setError(null)
                  }}
                  className="text-[var(--interactive-default)] hover:text-[var(--interactive-hover)]"
                >
                  Log in
                </button>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function GoogleIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden>
      <path
        fill="#4285F4"
        d="M23 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.2a5.3 5.3 0 0 1-2.3 3.5v2.9h3.7c2.2-2 3.4-5 3.4-8.6z"
      />
      <path
        fill="#34A853"
        d="M12 24c3.1 0 5.7-1 7.6-2.8l-3.7-2.9c-1 .7-2.3 1.1-3.9 1.1-3 0-5.5-2-6.4-4.7H1.8v3A12 12 0 0 0 12 24z"
      />
      <path fill="#FBBC05" d="M5.6 14.7a7.2 7.2 0 0 1 0-4.6v-3H1.8a12 12 0 0 0 0 10.6l3.8-3z" />
      <path
        fill="#EA4335"
        d="M12 4.8c1.7 0 3.2.6 4.4 1.7l3.3-3.3A11.6 11.6 0 0 0 12 0 12 12 0 0 0 1.8 7.1l3.8 3C6.5 6.8 9 4.8 12 4.8z"
      />
    </svg>
  )
}
