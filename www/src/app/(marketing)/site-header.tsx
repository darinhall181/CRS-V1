"use client"

import { useEffect, useRef, useState } from "react"
import { AltoscopeLogo } from "@/components/nav/logo"

// 2026-08-10 — was a plain always-visible sticky header (Darin: "I like the
// static bar less now"). Now a scroll-aware/auto-hiding header: slides up
// out of view on scroll-down, slides back in on scroll-up — same pattern as
// most modern marketing sites' nav bars. Always visible at the very top of
// the page regardless of direction, so it doesn't flicker on tiny scrolls.
export default function SiteHeader() {
  const [hidden, setHidden] = useState(false)
  const lastY = useRef(0)

  useEffect(() => {
    function onScroll() {
      const y = window.scrollY
      const goingDown = y > lastY.current
      lastY.current = y
      if (y < 96) {
        setHidden(false)
        return
      }
      setHidden(goingDown)
    }
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  return (
    <div
      style={{
        position: "sticky",
        top: 0,
        zIndex: 20,
        transform: hidden ? "translateY(-100%)" : "translateY(0)",
        transition: "transform 260ms ease",
      }}
    >
      <div
        aria-hidden
        style={{
          position: "absolute",
          inset: "0 0 auto 0",
          height: 140,
          background: "linear-gradient(to bottom, #101012 0%, #101012 54%, rgba(16,16,18,0) 100%)",
          pointerEvents: "none",
        }}
      />
      <header
        className="site-header"
        style={{
          position: "relative",
          height: 76,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <a href="#top" style={{ display: "inline-flex", alignItems: "center", gap: 11 }}>
          <AltoscopeLogo />
          <span style={{ fontSize: 17, fontWeight: 500, letterSpacing: "-0.01em", color: "#F4F4F5" }}>
            Altoscope
          </span>
        </a>
        <nav className="site-nav" style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12, letterSpacing: "0.04em", textTransform: "uppercase" }}>
          <a href="#features" className="link nav-link" style={{ padding: "8px 12px", textDecoration: "none" }}>
            Features
          </a>
          <a href="#about" className="link nav-link" style={{ padding: "8px 12px", textDecoration: "none" }}>
            About
          </a>
          <a
            href="#join"
            className="btn btn-primary"
            style={{
              color: "#fff",
              background: "#3D55A8",
              border: "1px solid #3D55A8",
              borderRadius: 999,
              padding: "8px 16px",
              textDecoration: "none",
            }}
          >
            Join
          </a>
        </nav>
      </header>
    </div>
  )
}
