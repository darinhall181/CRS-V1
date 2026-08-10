import type { Metadata } from "next"
import { GeistSans } from "geist/font/sans"
import { GeistMono } from "geist/font/mono"
import { Analytics } from "@vercel/analytics/next"
import { SpeedInsights } from "@vercel/speed-insights/next"
import "./globals.css"

// Site-wide fallback — wins on any route that doesn't export its own
// `metadata` (currently: /login, /package-builder — /browse has its own).
// Keep this in sync with (marketing)/page.tsx's TITLE/DESCRIPTION — that
// page overrides these for "/" itself, but this is what every other route
// (and any stale search-engine cache) falls back to, so a drift here reads
// as "the pitch changed but half the site didn't get the memo."
export const metadata: Metadata = {
  metadataBase: new URL("https://altoscope.so"),
  title: "Altoscope: Gear Rental and Preproduction Software",
  description:
    "A suite of intelligent tools to streamline your rental prep. Built for production companies.",
  keywords: ["gear rental software", "preproduction software", "camera compatibility", "lens mount", "RFQ", "cinematography gear"],
  openGraph: {
    title: "Altoscope: Gear Rental and Preproduction Software",
    description:
      "A suite of intelligent tools to streamline your rental prep. Built for production companies.",
    type: "website",
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={`${GeistSans.variable} ${GeistMono.variable}`}>
      <body className="min-h-screen bg-background font-sans antialiased">
        <main>{children}</main>
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  )
}
