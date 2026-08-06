"use client"

import Link from "next/link"
import Image from "next/image"
import { usePathname, useRouter } from "next/navigation"
import { cn } from "@/lib/utils"
import { authClient } from "@/lib/auth-client"
import { Button } from "@/components/ui/button"

const navLinks = [
  { href: "/", label: "Home" },
  { href: "/compatibility-checker", label: "Compatibility Checker" },
  { href: "/gear", label: "Gear" },
  { href: "/package-builder", label: "Package Builder" },
]

export function Navbar() {
  const pathname = usePathname()
  const router = useRouter()
  const { data: session } = authClient.useSession()

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="flex h-14 w-full items-center justify-between px-4 sm:px-6 lg:px-8">
        <Link href="/" className="flex items-center gap-2">
          <Image src="/logo.png" alt="Altoscope" width={28} height={28} className="h-7 w-auto" />
          <span className="font-semibold text-sm">Altoscope</span>
        </Link>

        <nav className="flex items-center gap-1">
          {navLinks.map(({ href, label }) => (
            <Link
              key={href}
              href={href}
              className={cn(
                "rounded-md px-3 py-1.5 text-sm transition-colors hover:bg-accent hover:text-accent-foreground",
                pathname === href
                  ? "bg-accent text-accent-foreground font-medium"
                  : "text-muted-foreground"
              )}
            >
              {label}
            </Link>
          ))}

          <div className="ml-2 flex items-center gap-2 border-l border-border/60 pl-3">
            {session ? (
              <>
                <span className="text-xs text-muted-foreground hidden sm:inline">
                  {session.user.email}
                </span>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={async () => {
                    await authClient.signOut()
                    router.push("/login")
                    router.refresh()
                  }}
                >
                  Sign out
                </Button>
              </>
            ) : (
              <Button variant="ghost" size="sm" asChild>
                <Link href="/login">Sign in</Link>
              </Button>
            )}
          </div>
        </nav>
      </div>
    </header>
  )
}
