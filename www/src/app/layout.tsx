import type { Metadata } from "next"
import { GeistSans } from "geist/font/sans"
import { GeistMono } from "geist/font/mono"
import { Analytics } from "@vercel/analytics/next"
import "./globals.css"
import { Navbar } from "@/components/nav/navbar"

export const metadata: Metadata = {
  title: "Altoscope — Camera & Lens Compatibility Intelligence",
  description:
    "Stop guessing. Altoscope cross-references every spec from thousands of cameras, lenses, and accessories so you always know what works together before you buy.",
  keywords: ["camera compatibility", "lens mount", "camera specs", "cinematography gear"],
  openGraph: {
    title: "Altoscope",
    description: "Camera & lens compatibility intelligence for filmmakers.",
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
        <Navbar />
        <main>{children}</main>
        <Analytics />
      </body>
    </html>
  )
}
