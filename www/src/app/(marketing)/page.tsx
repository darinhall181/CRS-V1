import type { Metadata } from "next"
import WaitlistForm from "./waitlist-form"
import SmoothScrollNav from "./smooth-scroll-nav"
import { AltoscopeLogo } from "@/components/nav/logo"

const TITLE = "Altoscope: Gear Rental and Preproduction Software"
const DESCRIPTION =
  "A suite of intelligent tools to streamline your rental prep. Built for production companies."

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  openGraph: {
    title: TITLE,
    description: DESCRIPTION,
    images: [{ url: "/marketing/og-banner.jpg", width: 1200, height: 630 }],
  },
  twitter: {
    card: "summary_large_image",
    title: TITLE,
    description: DESCRIPTION,
    images: ["/marketing/og-banner.jpg"],
  },
}

const HAIRLINE = "1px solid rgba(255,255,255,0.08)"
const MONO = "ui-monospace, SFMono-Regular, Menlo, monospace"

const PROCESS = [
  { n: "01", title: "Build", body: "Curate professional equipment lists for rent." },
  { n: "02", title: "Collaborate", body: "Check and approve equipment lists before sending RFQs." },
  { n: "03", title: "Send", body: "Send and receive dynamic RFQ links to finalize rental." },
]

const FEATURES = [
  {
    title: "Kit Builder",
    body: "Build custom camera packages from scratch, or start fast with scenario-matched templates for studio and mobile shoots.",
  },
  {
    title: "Compatibility Checker",
    body: "Automatically check mounts, media, and power to catch technical mismatches before the prep day.",
  },
  {
    title: "Budget Planner",
    body: "Visualize your kit’s scale and swap out alternative gear options to stay within your production’s budget tier.",
  },
  {
    title: "Centralized Research",
    body: "Access a unified, searchable database of verified public specs for bodies, lenses, and accessories.",
  },
  {
    title: "Instant RFQs",
    body: "One click reaches every rental house in your area. Eliminating a messy inbox.",
  },
  {
    title: "Team Collaboration",
    body: "Invite your team to build, edit, and comment on gear lists in one shared workspace.",
  },
]

const PRINCIPLES = [
  {
    title: "We’re obsessed with data accuracy.",
    body: "Our mission is to turn the noise of the internet into a clean, verified signal. We aggregate and standardize fragmented specs so you can trust the gear you are looking at.",
  },
  {
    title: "Confidence at the forefront",
    body: "Every kit is processed through our compatibility checker to catch errors before they happen. We are committed to delivering RFQs that rental houses respect and producers rely on.",
  },
  {
    title: "Focus on production speed",
    body: "We design workflows that prioritize your time and mental energy. Our focus is on removing the friction of logistics so you can dedicate your full attention to the shoot.",
  },
]

function SectionLabel({ label, num }: { label: string; num: string }) {
  return (
    <div
      className="section-label"
      style={{
        position: "sticky",
        top: 96,
        alignSelf: "start",
        display: "flex",
        justifyContent: "space-between",
        fontSize: 11,
        letterSpacing: "0.08em",
        textTransform: "uppercase",
        color: "rgba(255,255,255,0.40)",
      }}
    >
      <span>{label}</span>
      <span className="section-label-dot" style={{ fontFamily: MONO }}>
        ·
      </span>
      <span style={{ fontFamily: MONO }}>{num}</span>
    </div>
  )
}

const sectionShell = {
  maxWidth: 1240,
  margin: "0 auto",
  display: "grid",
  borderTop: HAIRLINE,
} as const

export default function LandingPage() {
  return (
    <div
      style={{
        background: "#18181A",
        color: "#F4F4F5",
        fontFamily: "'Aktiv Grotesk', ui-sans-serif, system-ui, sans-serif",
        WebkitFontSmoothing: "antialiased",
        minHeight: "100vh",
      }}
    >
      <SmoothScrollNav />
      <style>{`
        html { scroll-behavior: smooth; }
        @media (prefers-reduced-motion: reduce) {
          html { scroll-behavior: auto; }
        }
        #top, .section-shell { scroll-margin-top: 72px; }
        .btn {
          transition: transform 0.15s cubic-bezier(0.2, 0.8, 0.2, 1), background-color 0.18s ease, border-color 0.18s ease, opacity 0.18s ease;
        }
        .btn:hover { transform: translateY(-1px); }
        .btn:active { transform: translateY(0) scale(0.96); transition-duration: 0.08s; }
        .btn-ghost:hover { background: rgba(255,255,255,0.05); border-color: rgba(255,255,255,0.28); }
        .btn-primary:hover { background: #4a63bd; border-color: #4a63bd; }
        .btn-cta:hover { background: #ffd98f; }
        .link {
          transition: color 0.18s ease, opacity 0.18s ease;
        }
        .link:hover { color: #F4F4F5; opacity: 1; }
        .nav-link { color: rgba(255,255,255,0.55); }
        .nav-link:hover { color: #F4F4F5; }
        @media (prefers-reduced-motion: reduce) {
          .btn, .btn:hover, .btn:active, .link { transition: none !important; transform: none !important; }
        }

        .site-header { padding: 0 40px; }
        .site-nav { gap: 8px; }
        .hero { padding: 72px 40px 96px; }
        .section-shell { padding: 56px 40px; grid-template-columns: 200px 1fr; gap: 48px; }
        .section-shell-join { padding-bottom: 96px; }
        .process-row { grid-template-columns: 64px 200px 1fr; gap: 24px; }
        .features-grid { grid-template-columns: 1fr 1fr; gap: 0 48px; }
        .about-hero-img { height: 280px; }
        .principles-grid { grid-template-columns: 1fr 1fr 1fr; column-gap: 40px; }
        .bios-grid { grid-template-columns: 1fr 1fr; gap: 32px; }
        .bio-avatar { width: 140px; height: 140px; }
        .footer-grid { padding: 28px 40px; grid-template-columns: 200px 1fr 1fr; gap: 32px; }
        .section-label-dot { display: none; }

        @media (max-width: 900px) {
          .section-shell { grid-template-columns: 1fr; gap: 20px; }
          .principles-grid { grid-template-columns: 1fr; gap: 24px; }
          .bios-grid { grid-template-columns: 1fr; gap: 40px; }
        }

        @media (max-width: 640px) {
          .site-header { padding: 0 20px; }
          .site-nav { gap: 2px; font-size: 11px; }
          .site-nav a { padding: 8px !important; }
          .hero { padding: 40px 20px 56px !important; }
          .hero-cta-row { flex-direction: column; align-items: flex-start !important; gap: 24px !important; }
          .section-shell { padding: 40px 20px !important; }
          .section-shell-join { padding-bottom: 64px !important; }
          .process-row { grid-template-columns: 1fr !important; gap: 4px !important; }
          .process-num { display: none; }
          .features-grid { grid-template-columns: 1fr !important; gap: 0 !important; }
          .about-hero-img { height: 180px !important; margin-bottom: 32px !important; }
          .bio-avatar { width: 96px !important; height: 96px !important; }
          .footer-grid { padding: 24px 20px !important; grid-template-columns: 1fr !important; gap: 24px !important; }
          .section-label { position: static !important; justify-content: flex-start !important; gap: 6px; }
          .section-label-dot { display: inline; opacity: 0.5; }
        }
      `}</style>
      {/* Sticky header, restyled 2026-08-10 to match the app's Elevation Kit
          TopBar (www/src/components/elevation/TopBar.tsx) — same logo mark +
          wordmark treatment (23px mark, 17px medium wordmark, 11px gap), same
          taller/more spacious footprint — instead of the search pill and
          account/bell cluster (nothing to search, nobody's signed in yet)
          the right side keeps this page's own Features/About/Join links.
          The hard border+uniform-blur cutoff is gone too: a taller
          absolutely-positioned layer beneath the header content carries the
          actual blur+background wash and fades it out via a mask gradient,
          so text scrolling underneath blurs in gradually instead of hitting
          a hard edge. */}
      <div style={{ position: "sticky", top: 0, zIndex: 20 }}>
        <div
          aria-hidden
          style={{
            position: "absolute",
            inset: "0 0 auto 0",
            height: 128,
            backdropFilter: "blur(18px)",
            WebkitBackdropFilter: "blur(18px)",
            background: "linear-gradient(to bottom, rgba(16,16,18,0.78) 0%, rgba(16,16,18,0.5) 45%, rgba(16,16,18,0) 100%)",
            maskImage: "linear-gradient(to bottom, #000 0%, #000 40%, transparent 100%)",
            WebkitMaskImage: "linear-gradient(to bottom, #000 0%, #000 40%, transparent 100%)",
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

      <section id="top" className="hero" style={{ maxWidth: 1240, margin: "0 auto", display: "flex", flexDirection: "column", gap: 56 }}>
        <h1
          style={{
            margin: 0,
            fontSize: "clamp(48px, 8vw, 104px)",
            lineHeight: 0.96,
            fontWeight: 300,
            letterSpacing: "-0.04em",
            maxWidth: "16ch",
            textWrap: "balance",
            color: "rgba(255,255,255,0.52)",
          }}
        >
          Where Productions Get Gear-<em style={{ fontStyle: "italic", color: "#F4F4F5" }}>Ready</em>.
        </h1>
        <div className="hero-cta-row" style={{ display: "flex", alignItems: "flex-end", justifyContent: "space-between", gap: 48, flexWrap: "wrap" }}>
          <p style={{ margin: 0, fontSize: 18, lineHeight: 1.5, color: "rgba(255,255,255,0.58)", maxWidth: "38ch", textWrap: "pretty" }}>
            A suite of intelligent tools to streamline your rental prep. Built for production companies.
          </p>
          <div style={{ display: "flex", gap: 10 }}>
            <a
              href="#features"
              className="btn btn-ghost"
              style={{
                whiteSpace: "nowrap",
                display: "inline-flex",
                alignItems: "center",
                height: 44,
                padding: "0 22px",
                border: "1px solid rgba(255,255,255,0.16)",
                borderRadius: 999,
                color: "#F4F4F5",
                fontSize: 13,
                textDecoration: "none",
              }}
            >
              See features
            </a>
            <a
              href="#join"
              className="btn btn-primary"
              style={{
                whiteSpace: "nowrap",
                display: "inline-flex",
                alignItems: "center",
                height: 44,
                padding: "0 22px",
                borderRadius: 999,
                background: "#3D55A8",
                color: "#fff",
                fontSize: 13,
                fontWeight: 500,
                textDecoration: "none",
              }}
            >
              Join the Waitlist
            </a>
          </div>
        </div>
      </section>

      <section id="process" className="section-shell" style={sectionShell}>
        <SectionLabel label="Process" num="001" />
        <div style={{ display: "flex", flexDirection: "column" }}>
          <h2 style={{ margin: "0 0 40px", fontSize: "clamp(28px, 3.4vw, 42px)", lineHeight: 1.1, fontWeight: 300, letterSpacing: "-0.03em", maxWidth: "22ch" }}>
            Your rentals, effortlessly.
          </h2>
          <p style={{ margin: "0 0 48px", fontSize: 16, lineHeight: 1.55, color: "rgba(255,255,255,0.58)", maxWidth: "46ch" }}>
            Your entire gear list, planning, and collaboration all in one place.
          </p>
          {PROCESS.map((s, i) => (
            <div
              key={s.n}
              className="process-row"
              style={{
                display: "grid",
                alignItems: "baseline",
                padding: "28px 0",
                borderTop: HAIRLINE,
                borderBottom: i === PROCESS.length - 1 ? HAIRLINE : undefined,
              }}
            >
              <span className="process-num" style={{ fontFamily: MONO, fontSize: 12, color: "rgba(255,255,255,0.30)" }}>{s.n}</span>
              <h3 style={{ margin: 0, fontSize: 24, fontWeight: 400, letterSpacing: "-0.02em" }}>{s.title}</h3>
              <p style={{ margin: 0, fontSize: 15, lineHeight: 1.55, color: "rgba(255,255,255,0.58)" }}>{s.body}</p>
            </div>
          ))}
        </div>
      </section>

      <section id="features" className="section-shell" style={sectionShell}>
        <SectionLabel label="Features" num="002" />
        <div style={{ display: "flex", flexDirection: "column" }}>
          <h2 style={{ margin: "0 0 24px", fontSize: "clamp(28px, 3.4vw, 42px)", lineHeight: 1.1, fontWeight: 300, letterSpacing: "-0.03em", maxWidth: "22ch" }}>
            Reasons you will love us.
          </h2>
          <p style={{ margin: "0 0 48px", fontSize: 16, lineHeight: 1.55, color: "rgba(255,255,255,0.58)", maxWidth: "46ch" }}>
            Specs, budget, and quotes in one place.
          </p>
          <div className="features-grid" style={{ display: "grid" }}>
            {FEATURES.map((f, i) => (
              <div
                key={f.title}
                style={{
                  padding: "26px 0",
                  borderTop: HAIRLINE,
                  borderBottom: i >= FEATURES.length - 2 ? HAIRLINE : undefined,
                  display: "flex",
                  flexDirection: "column",
                  gap: 10,
                }}
              >
                <h3 style={{ margin: 0, fontSize: 18, fontWeight: 500, letterSpacing: "-0.01em" }}>{f.title}</h3>
                <p style={{ margin: 0, fontSize: 14, lineHeight: 1.55, color: "rgba(255,255,255,0.56)" }}>{f.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="about" className="section-shell" style={sectionShell}>
        <SectionLabel label="About" num="003" />
        <div style={{ display: "flex", flexDirection: "column" }}>
          <h2 style={{ margin: "0 0 24px", fontSize: "clamp(28px, 3.4vw, 42px)", lineHeight: 1.1, fontWeight: 300, letterSpacing: "-0.03em", maxWidth: "20ch" }}>
            Helping you streamline your rental workflow.
          </h2>
          <p style={{ margin: "0 0 48px", fontSize: 16, lineHeight: 1.55, color: "rgba(255,255,255,0.58)", maxWidth: "52ch" }}>
            We’re building a system replacing scattered emails with a unified standard that connects producers, DPs, and rental houses.
          </p>

          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/marketing/about-hero.jpg"
            alt="On set during camera prep"
            className="about-hero-img"
            style={{ width: "100%", objectFit: "cover", borderRadius: 12, marginBottom: 56, display: "block" }}
          />

          <div className="principles-grid" style={{ display: "grid", gap: 24, paddingTop: 28, borderTop: HAIRLINE }}>
            {PRINCIPLES.map((p) => (
              <div key={p.title} style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                <h3 style={{ margin: 0, fontSize: 17, fontWeight: 500, letterSpacing: "-0.01em" }}>{p.title}</h3>
                <p style={{ margin: 0, fontSize: 14, lineHeight: 1.55, color: "rgba(255,255,255,0.56)" }}>{p.body}</p>
              </div>
            ))}
          </div>

          <div className="bios-grid" style={{ display: "grid", marginTop: 56 }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 20, paddingTop: 28, borderTop: HAIRLINE }}>
              <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="/marketing/darin.jpg" alt="Darin" className="bio-avatar" style={{ objectFit: "cover", borderRadius: 12 }} />
                <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
                  <h3 style={{ margin: 0, fontSize: 20, fontWeight: 400, letterSpacing: "-0.02em" }}>I’m Darin!</h3>
                  <span style={{ fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: "rgba(255,255,255,0.40)" }}>Founder</span>
                </div>
              </div>
              <p style={{ margin: 0, fontSize: 14, lineHeight: 1.6, color: "rgba(255,255,255,0.56)" }}>
                I’m Darin, a photographer and data scientist passionate about creating software solutions for other creatives. This vision stems from the
                frustration with how to find camera gear on the internet.
              </p>
              <p style={{ margin: 0, fontSize: 14, lineHeight: 1.6, color: "rgba(255,255,255,0.56)" }}>
                Altoscope started as a personal project—a tool I built just to solve my own headaches. But the more I talked to other professionals, the more I
                realized I wasn’t alone. Our industry is incredible at creating content, yet we’re still stuck with outdated, fragmented workflows. I want to
                change that.
              </p>
              <p style={{ margin: 0, fontSize: 14, lineHeight: 1.6, color: "rgba(255,255,255,0.56)" }}>
                Feel free to reach out at{" "}
                <a href="mailto:darin@altoscope.so" style={{ color: "#8FA3E0", textDecoration: "none" }}>
                  darin@altoscope.so
                </a>{" "}
                to schedule a call or just say hi :)
              </p>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: 20, paddingTop: 28, borderTop: HAIRLINE }}>
              <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="/marketing/kevin.jpg" alt="Kevin" className="bio-avatar" style={{ objectFit: "cover", borderRadius: 12 }} />
                <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
                  <h3 style={{ margin: 0, fontSize: 20, fontWeight: 400, letterSpacing: "-0.02em" }}>I’m Kevin!</h3>
                  <span style={{ fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: "rgba(255,255,255,0.40)" }}>CFO</span>
                </div>
              </div>
              <p style={{ margin: 0, fontSize: 14, lineHeight: 1.6, color: "rgba(255,255,255,0.56)" }}>
                I’m Kevin, a photographer pursuing neuroscience and finance. Having met Darin while he was working on this project, I jumped headfirst into this
                project with the same passion.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section id="join" className="section-shell section-shell-join" style={sectionShell}>
        <SectionLabel label="Waitlist" num="004" />
        <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
          <h2 style={{ margin: 0, fontSize: "clamp(36px, 5vw, 64px)", lineHeight: 1.02, fontWeight: 300, letterSpacing: "-0.035em" }}>Are you ready?</h2>
          <p style={{ margin: 0, fontSize: 16, lineHeight: 1.55, color: "rgba(255,255,255,0.58)", maxWidth: "44ch" }}>
            Join the waitlist to get behind-the-scenes access &amp; join the beta testing team.
          </p>
          <WaitlistForm />
        </div>
      </section>

      <footer
        className="footer-grid"
        style={{
          maxWidth: 1240,
          margin: "0 auto",
          borderTop: HAIRLINE,
          display: "grid",
        }}
      >
        <a href="#top" style={{ color: "#F4F4F5", fontSize: 15, fontWeight: 600, letterSpacing: "-0.01em", alignSelf: "start", textDecoration: "none" }}>
          Altoscope
        </a>
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <span style={{ fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: "rgba(255,255,255,0.40)" }}>Contact</span>
          <a href="mailto:darin@altoscope.so" style={{ fontSize: 13, color: "#8FA3E0", textDecoration: "none" }}>
            darin@altoscope.so
          </a>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <span style={{ fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: "rgba(255,255,255,0.40)" }}>
            Demo Login Information
          </span>
          <a href="/login" className="link" style={{ fontSize: 13, color: "#8FA3E0", textDecoration: "none" }}>
            Demo Login
          </a>
        </div>
        <div style={{ gridColumn: "1 / -1", paddingTop: 20, fontSize: 12, color: "rgba(255,255,255,0.32)" }}>© Altoscope 2026</div>
      </footer>
    </div>
  )
}
