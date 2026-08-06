"use client"

import { useState } from "react"

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

export default function WaitlistForm() {
  const [email, setEmail] = useState("")
  const [status, setStatus] = useState("")
  const [ok, setOk] = useState<boolean | null>(null)
  const [submitting, setSubmitting] = useState(false)

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    const value = email.trim()
    if (!EMAIL.test(value)) {
      setStatus("Enter a valid email address.")
      setOk(false)
      return
    }
    setStatus("Adding you…")
    setOk(null)
    setSubmitting(true)
    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: value }),
      })
      if (!res.ok) throw new Error(String(res.status))
      setEmail("")
      setStatus("You’re on the list. We’ll be in touch before beta.")
      setOk(true)
    } catch {
      setStatus("Couldn’t reach the server. Try again in a moment.")
      setOk(false)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <>
      <style>{`
        .waitlist-input { transition: border-color 0.18s ease, background-color 0.18s ease; }
        .waitlist-input:focus { border-color: rgba(255,255,255,0.28); background: #34343b; }
        .waitlist-btn { transition: transform 0.15s cubic-bezier(0.2, 0.8, 0.2, 1), background-color 0.18s ease, opacity 0.18s ease; }
        .waitlist-btn:hover:not(:disabled) { transform: translateY(-1px); background: #ffd98f; }
        .waitlist-btn:active:not(:disabled) { transform: translateY(0) scale(0.96); transition-duration: 0.08s; }
        .waitlist-btn:disabled { opacity: 0.6; cursor: default; }
        @media (prefers-reduced-motion: reduce) {
          .waitlist-input, .waitlist-btn, .waitlist-btn:hover, .waitlist-btn:active { transition: none !important; transform: none !important; }
        }
      `}</style>
      <form onSubmit={onSubmit} style={{ display: "flex", gap: 8, width: "100%", maxWidth: 480, marginTop: 8 }}>
        <input
          type="email"
          required
          placeholder="you@production.com"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value)
            setStatus("")
            setOk(null)
          }}
          className="waitlist-input"
          style={{
            flex: 1,
            minWidth: 0,
            height: 40,
            background: "#2E2E34",
            border: "1px solid rgba(255,255,255,0.10)",
            borderRadius: 8,
            padding: "0 14px",
            color: "#F4F4F5",
            fontSize: 14,
            fontFamily: "inherit",
            outline: "none",
          }}
        />
        <button
          type="submit"
          disabled={submitting}
          className="waitlist-btn"
          style={{
            flex: "0 0 auto",
            whiteSpace: "nowrap",
            height: 40,
            padding: "0 20px",
            border: "none",
            borderRadius: 8,
            background: "#FFCF7B",
            color: "#18181A",
            fontSize: 14,
            fontWeight: 600,
            fontFamily: "inherit",
            cursor: "pointer",
          }}
        >
          {submitting ? "Adding…" : "Join the waitlist ↗"}
        </button>
      </form>
      <p
        style={{
          margin: 0,
          minHeight: 18,
          fontSize: 13,
          color: ok === false ? "#E0A0A0" : ok ? "#8FBF9F" : "rgba(255,255,255,0.42)",
        }}
      >
        {status}
      </p>
    </>
  )
}
