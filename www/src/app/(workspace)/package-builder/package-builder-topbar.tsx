"use client"

import { TopBar } from "@/components/elevation"
import { AltoscopeLogo } from "@/components/nav/logo"
import { AccountMenu } from "@/components/nav/account-menu"

// Package Builder's global top bar — a thin composition of the Elevation Kit
// `TopBar` primitive (solidified 2026-08-08 once the full-width-bar-above-
// the-sidebar layout and the logo/wordmark move off SidebarNav both settled).
// Logo and account menu are shared with (app)'s AppShell (T0016) so they
// can't drift; only the search placeholder stays page-specific here.
export function PackageBuilderTopBar({ userName }: { userName: string }) {
  return (
    <TopBar
      logo={<AltoscopeLogo />}
      wordmark="Altoscope"
      searchPlaceholder="Search gear, packages, rental houses"
      userMenu={<AccountMenu userName={userName} />}
    />
  )
}
