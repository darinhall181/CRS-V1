"use client"

import { useRouter } from "next/navigation"
import { authClient } from "@/lib/auth-client"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

// Shared account/sign-out dropdown for every TopBar usage — same real
// Better Auth sign-out, same avatar-initials treatment, so it doesn't drift
// between Package Builder's top bar and the (app) group's shared AppShell.
export function AccountMenu({ userName }: { userName: string }) {
  const router = useRouter()

  return (
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
  )
}
