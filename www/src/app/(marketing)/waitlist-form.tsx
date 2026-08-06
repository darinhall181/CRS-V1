"use client"

import { useState } from "react"

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

export default function WaitlistForm() {
  const [email, setEmail] = useState("")
  const [status, setStatus] = useState("")
  const [ok, setOk] = useState<boolean | null>(null)

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
    }
  }

  return (
    <>
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
          Join the waitlist ↗
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
