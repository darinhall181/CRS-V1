"use client"

import { useRouter, useSearchParams } from "next/navigation"
import Link from "next/link"
import { ArrowLeft } from "lucide-react"
import { cn } from "@/lib/utils"
import { FOCUS_RING } from "@/components/elevation/shared"

// Public by design — this is exactly the page someone lands on when a
// sign-in attempt FAILED, so it can never require being signed in. Better
// Auth's own default (a generic unstyled page at /api/auth/error) is
// redirected here via auth.ts's onAPIError.errorURL, added 2026-08-10 after
// a real access_denied hit during Google OAuth testing.
const ERROR_MESSAGES: Record<string, string> = {
  access_denied:
    "Google didn't complete the sign-in — either it was cancelled, or (while the app's OAuth consent screen is still in testing mode) this Google account hasn't been added as a test user yet.",
  invalid_callback:
    "That sign-in link is no longer valid — it may have expired or already been used.",
}

function describeError(code: string | null): string {
  if (!code) return "Something went wrong during sign-in."
  return ERROR_MESSAGES[code] ?? `Something went wrong during sign-in (${code}).`
}

export default function AuthErrorPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const code = searchParams.get("error")
  const description = searchParams.get("error_description")

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-6 bg-[var(--bg-base)] px-8 text-center text-[var(--text-primary)]">
      <div className="flex w-full max-w-[420px] flex-col items-center gap-5">
        <div
          className="flex h-14 w-14 items-center justify-center rounded-2xl shadow-[var(--elevation-1)]"
          style={{ background: "#34343B" }}
        >
          <span className="text-2xl">⚠</span>
        </div>

        <div className="flex flex-col gap-2">
          <h1 className="m-0 text-[22px] font-medium tracking-[-0.015em]">Sign-in didn&apos;t go through</h1>
          <p className="m-0 text-[13px] leading-[1.6] text-[var(--text-secondary)]">{describeError(code)}</p>
          {description && (
            <p className="m-0 text-[11px] text-[var(--text-subtle)]">{description}</p>
          )}
          {code && (
            <p className="m-0 font-mono text-[11px] text-[var(--text-subtle)]">code: {code}</p>
          )}
        </div>

        <div className="flex items-center gap-[14px]">
          <button
            type="button"
            onClick={() => router.back()}
            className={cn(
              "flex h-[42px] items-center gap-[7px] rounded-[10px] border-none bg-transparent px-4 text-[13px] font-medium text-[var(--text-secondary)] hover:bg-white/[0.04]",
              FOCUS_RING
            )}
          >
            <ArrowLeft size={15} strokeWidth={1.8} />
            Back
          </button>
          <Link
            href="/login"
            className={cn(
              "flex h-[42px] items-center justify-center rounded-[10px] border-none px-7 text-[13px] font-medium text-white transition-opacity hover:opacity-90",
              FOCUS_RING
            )}
            style={{ background: "var(--interactive-default)" }}
          >
            Log in again
          </Link>
        </div>
      </div>
    </div>
  )
}
