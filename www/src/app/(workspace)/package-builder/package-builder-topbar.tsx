"use client"

import Image from "next/image"
import { useRouter } from "next/navigation"
import { authClient } from "@/lib/auth-client"
import { TopBar } from "@/components/elevation"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

// h-[23px] w-[23px] forces a true square — the source PNG isn't square
// (1328x1696), and Tailwind's preflight `img { height: auto }` otherwise wins
// over the Image component's height attribute, stretching it to ~29px tall.
const LOGO = (
  <Image src="/altoscope-mark-white.png" alt="" width={23} height={23} className="h-[23px] w-[23px] flex-none object-contain" />
)

// Package Builder's global top bar — a thin composition of the Elevation Kit
// `TopBar` primitive (solidified 2026-08-08 once the full-width-bar-above-
// the-sidebar layout and the logo/wordmark move off SidebarNav both settled).
// Everything app-specific stays here rather than in the primitive: the real
// logo asset, and the profile dropdown (Better Auth sign-out) passed in as
// `userMenu`.
export function PackageBuilderTopBar({ userName }: { userName: string }) {
  const router = useRouter()

  return (
    <TopBar
      logo={LOGO}
      wordmark="Altoscope"
      searchPlaceholder="Search gear, packages, rental houses"
      userMenu={
        <DropdownMenu>
          <DropdownMenuTrigger className="flex items-center gap-2 outline-none">
            <div className="flex h-[36px] w-[36px] items-center justify-center rounded-full bg-[var(--interactive-default)] text-[13px] font-medium text-white">
              {userName.slice(0, 2).toUpperCase()}
            </div>
            <span className="text-[15px] font-medium text-[var(--text-primary)]">{userName}</span>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem
              onClick={async () => {
                await authClient.signOut()
                router.push("/login")
                router.refresh()
              }}
            >
              Sign out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      }
    />
  )
}
