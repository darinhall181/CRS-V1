// (workspace) — pages with their own full shell (sidebar + top bar), e.g.
// package-builder. Deliberately does NOT render the shared marketing-style
// <Navbar/> that (app)/layout.tsx uses — see T0016 for the still-open
// app-wide nav-shell decision this is a first, page-scoped step toward.
export default function WorkspaceLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>
}
