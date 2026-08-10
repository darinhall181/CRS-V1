import { AuthForm } from "@/components/auth/auth-form"

export const metadata = {
  title: "Create an account — Altoscope",
}

export default function RegisterPage() {
  return <AuthForm mode="sign-up" />
}
