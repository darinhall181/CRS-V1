"use client"

import { useEffect } from "react"

export default function SmoothScrollNav() {
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      const anchor = (e.target as HTMLElement).closest('a[href^="#"]') as HTMLAnchorElement | null
      if (!anchor) return

      const id = anchor.getAttribute("href")?.slice(1)
      if (!id) return

      const el = document.getElementById(id)
      if (!el) return

      e.preventDefault()
      el.scrollIntoView({ behavior: "smooth", block: "start" })
    }

    document.addEventListener("click", handleClick)
    return () => document.removeEventListener("click", handleClick)
  }, [])

  return null
}
