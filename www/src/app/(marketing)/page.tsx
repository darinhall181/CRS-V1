import Link from "next/link"
import { ArrowRight, Camera, CheckCircle, Database, Layers, Search, Zap } from "lucide-react"

export default function HomePage() {
  return (
    <div className="flex flex-col">
      {/* Hero */}
      <section className="relative overflow-hidden border-b bg-gradient-to-b from-background to-muted/30 py-24 sm:py-32">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="mx-auto max-w-3xl text-center">
            <span className="inline-flex items-center rounded-full border bg-background px-3 py-1 text-xs font-medium text-muted-foreground">
              Canon cameras & lenses — more brands coming soon
            </span>
            <h1 className="mt-6 text-4xl font-bold tracking-tight sm:text-6xl">
              Stop guessing if your gear works together.
            </h1>
            <p className="mt-6 text-lg text-muted-foreground sm:text-xl">
              Altoscope cross-references thousands of cameras, lenses, and accessories so you always
              know what&apos;s compatible — before you buy or rent.
            </p>
            <div className="mt-10 flex flex-col items-center gap-4 sm:flex-row sm:justify-center">
              <Link
                href="/compatibility-checker"
                className="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground transition-opacity hover:opacity-90"
              >
                Try Compatibility Checker
                <ArrowRight className="h-4 w-4" />
              </Link>
              <Link
                href="/gear"
                className="inline-flex items-center gap-2 rounded-lg border px-6 py-3 text-sm font-semibold transition-colors hover:bg-accent"
              >
                Browse Gear
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="border-b py-12">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <dl className="grid grid-cols-2 gap-8 sm:grid-cols-4">
            {[
              { value: "500+", label: "Products catalogued" },
              { value: "60+", label: "Spec fields per product" },
              { value: "5+", label: "Lens mounts covered" },
              { value: "100%", label: "Structured data" },
            ].map(({ value, label }) => (
              <div key={label} className="text-center">
                <dt className="text-3xl font-bold tracking-tight">{value}</dt>
                <dd className="mt-1 text-sm text-muted-foreground">{label}</dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 sm:py-28">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
              Everything you need to know, in one place.
            </h2>
            <p className="mt-4 text-muted-foreground">
              Our data pipeline scrapes manufacturer specs and normalises them into a structured
              database you can actually query.
            </p>
          </div>

          <div className="mt-16 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {[
              {
                icon: Search,
                title: "Compatibility Checker",
                description:
                  "Select a camera body and a lens to instantly see whether they share a mount, whether an adapter is needed, and what features you&apos;d lose.",
              },
              {
                icon: Database,
                title: "Structured Spec Database",
                description:
                  "Every spec — sensor size, mount type, focal length, aperture range — is stored as typed, queryable data, not a blob of HTML.",
              },
              {
                icon: Layers,
                title: "Multi-Brand Coverage",
                description:
                  "Canon EF, RF, CN-E, and EF Cinema lenses today. Nikon Z, Sony E, and ARRI PL support shipping soon.",
              },
              {
                icon: Camera,
                title: "Full Gear Detail Pages",
                description:
                  "Browse spec sheets for every camera body and lens with images, section-grouped specs, and links to official documentation.",
              },
              {
                icon: Zap,
                title: "Always Up-to-Date",
                description:
                  "Our automated scraping pipeline re-runs on demand to catch newly released products and spec corrections.",
              },
              {
                icon: CheckCircle,
                title: "Rental & Purchase Ready",
                description:
                  "Whether you&apos;re renting for a shoot or building a kit, get a definitive answer before money changes hands.",
              },
            ].map(({ icon: Icon, title, description }) => (
              <div
                key={title}
                className="rounded-xl border bg-card p-6 shadow-sm transition-shadow hover:shadow-md"
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                  <Icon className="h-5 w-5 text-primary" />
                </div>
                <h3 className="mt-4 font-semibold">{title}</h3>
                <p className="mt-2 text-sm text-muted-foreground">{description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section className="border-t bg-muted/30 py-20 sm:py-28">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Simple pricing</h2>
            <p className="mt-4 text-muted-foreground">
              Free while we&apos;re in beta. Pro features coming soon.
            </p>
          </div>

          <div className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {/* Free */}
            <div className="rounded-xl border bg-card p-8 shadow-sm">
              <h3 className="font-semibold">Free</h3>
              <p className="mt-2 text-4xl font-bold">
                $0<span className="text-base font-normal text-muted-foreground">/mo</span>
              </p>
              <p className="mt-2 text-sm text-muted-foreground">Always free</p>
              <ul className="mt-6 space-y-3 text-sm">
                {[
                  "Browse all gear specs",
                  "Basic compatibility checks",
                  "Up to 20 checks/day",
                ].map((feat) => (
                  <li key={feat} className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 flex-shrink-0 text-primary" />
                    {feat}
                  </li>
                ))}
              </ul>
              <Link
                href="/compatibility-checker"
                className="mt-8 block rounded-lg border px-4 py-2 text-center text-sm font-medium transition-colors hover:bg-accent"
              >
                Get started free
              </Link>
            </div>

            {/* Pro */}
            <div className="relative rounded-xl border-2 border-primary bg-card p-8 shadow-md">
              <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-primary px-3 py-0.5 text-xs font-semibold text-primary-foreground">
                Coming soon
              </span>
              <h3 className="font-semibold">Pro</h3>
              <p className="mt-2 text-4xl font-bold">
                $12<span className="text-base font-normal text-muted-foreground">/mo</span>
              </p>
              <p className="mt-2 text-sm text-muted-foreground">Billed annually</p>
              <ul className="mt-6 space-y-3 text-sm">
                {[
                  "Everything in Free",
                  "Unlimited compatibility checks",
                  "Save & share gear lists",
                  "CSV / JSON spec exports",
                  "Email alerts for new products",
                ].map((feat) => (
                  <li key={feat} className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 flex-shrink-0 text-primary" />
                    {feat}
                  </li>
                ))}
              </ul>
              <button
                disabled
                className="mt-8 w-full cursor-not-allowed rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground opacity-60"
              >
                Join waitlist
              </button>
            </div>

            {/* Enterprise */}
            <div className="rounded-xl border bg-card p-8 shadow-sm">
              <h3 className="font-semibold">Enterprise</h3>
              <p className="mt-2 text-4xl font-bold">Custom</p>
              <p className="mt-2 text-sm text-muted-foreground">For rental houses &amp; studios</p>
              <ul className="mt-6 space-y-3 text-sm">
                {[
                  "Everything in Pro",
                  "API access",
                  "Bulk inventory imports",
                  "Dedicated account manager",
                  "Custom brand coverage",
                ].map((feat) => (
                  <li key={feat} className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 flex-shrink-0 text-primary" />
                    {feat}
                  </li>
                ))}
              </ul>
              <a
                href="mailto:hello@altoscope.io"
                className="mt-8 block rounded-lg border px-4 py-2 text-center text-sm font-medium transition-colors hover:bg-accent"
              >
                Contact us
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="border-t py-20">
        <div className="mx-auto max-w-6xl px-4 text-center sm:px-6">
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Ready to check your kit?
          </h2>
          <p className="mt-4 text-muted-foreground">
            No account needed. Just pick your gear and get an instant answer.
          </p>
          <Link
            href="/compatibility-checker"
            className="mt-8 inline-flex items-center gap-2 rounded-lg bg-primary px-8 py-3 text-sm font-semibold text-primary-foreground transition-opacity hover:opacity-90"
          >
            Open Compatibility Checker
            <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      </section>
    </div>
  )
}
