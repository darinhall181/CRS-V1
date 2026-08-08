"use client"

import { useState } from "react"
import { authClient } from "../lib/auth-client"

export default function Home() {
  const [mode, setMode] = useState<"signin" | "signup">("signin")
  const [name, setName] = useState("")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState("")
  const [success, setSuccess] = useState("")

  const { data: session } = authClient.useSession()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError("")
    setSuccess("")

    if (mode === "signup") {
      const { error } = await authClient.signUp.email({ name, email, password })
      if (error) setError(error.message ?? "Sign up failed")
      else setSuccess("Account created! You are now signed in.")
    } else {
      const { error } = await authClient.signIn.email({ email, password })
      if (error) setError(error.message ?? "Sign in failed")
      else setSuccess("Signed in successfully.")
    }
  }

  async function handleSignOut() {
    await authClient.signOut()
    setSuccess("")
  }

  if (session) {
    return (
      <main className="flex flex-1 flex-col items-center justify-center gap-4">
        <p className="text-lg">Signed in as <strong>{session.user.email}</strong></p>
        <button
          onClick={handleSignOut}
          className="rounded-full bg-black text-white px-6 py-2 text-sm font-medium hover:bg-zinc-700"
        >
          Sign out
        </button>
      </main>
    )
  }

  return (
    <main className="flex flex-1 flex-col items-center justify-center">
      <div className="w-full max-w-sm flex flex-col gap-6">
        <div className="flex gap-4 text-sm font-medium border-b border-zinc-200 pb-3">
          <button
            onClick={() => setMode("signin")}
            className={mode === "signin" ? "text-black" : "text-zinc-400"}
          >
            Sign in
          </button>
          <button
            onClick={() => setMode("signup")}
            className={mode === "signup" ? "text-black" : "text-zinc-400"}
          >
            Sign up
          </button>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          {mode === "signup" && (
            <input
              type="text"
              placeholder="Name"
              value={name}
              onChange={e => setName(e.target.value)}
              required
              className="border border-zinc-200 rounded-lg px-4 py-2 text-sm outline-none focus:border-zinc-400"
            />
          )}
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            required
            className="border border-zinc-200 rounded-lg px-4 py-2 text-sm outline-none focus:border-zinc-400"
          />
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            className="border border-zinc-200 rounded-lg px-4 py-2 text-sm outline-none focus:border-zinc-400"
          />
          {error && <p className="text-red-500 text-sm">{error}</p>}
          {success && <p className="text-green-600 text-sm">{success}</p>}
          <button
            type="submit"
            className="rounded-full bg-black text-white px-6 py-2 text-sm font-medium hover:bg-zinc-700"
          >
            {mode === "signin" ? "Sign in" : "Sign up"}
          </button>
        </form>
      </div>
    </main>
  )
}
