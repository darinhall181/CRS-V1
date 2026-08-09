import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { useState } from "react"
import { LayoutDashboard, Package, FileText, Building2, Settings } from "lucide-react"
import { SidebarNav } from "./SidebarNav"

const meta: Meta<typeof SidebarNav> = {
  title: "Elevation Kit/SidebarNav",
  component: SidebarNav,
  parameters: { layout: "fullscreen" },
}
export default meta
type Story = StoryObj<typeof SidebarNav>

const ICON = { size: 15, strokeWidth: 1.7 }
const LOGO = (
  <div className="h-[19px] w-[19px] rounded-[4px] bg-[var(--interactive-default)]" />
)

// Package Builder — flush (no boxed panel), trimmed nav + a Settings group
// below a divider, collapsible to a 64px icon rail with circular ("shrunken
// pill") items instead of squares.
export const FlushCollapsible: Story = {
  render: function Render() {
    const [collapsed, setCollapsed] = useState(false)
    const items = [
      { label: "Dashboard", icon: <LayoutDashboard {...ICON} /> },
      { label: "Browse", icon: <Package {...ICON} className="rotate-45" /> },
      { label: "Packages", icon: <Package {...ICON} /> },
      { label: "Quotes", icon: <FileText {...ICON} /> },
    ]
    return (
      <div style={{ height: "100vh", background: "var(--bg-base)" }}>
        <SidebarNav
          logo={LOGO}
          wordmark="Altoscope"
          flush
          items={items.map((i) => ({ ...i, active: i.label === "Packages" }))}
          secondaryItems={[{ label: "Settings", icon: <Settings {...ICON} /> }]}
          workspaces={[
            { name: "Harpeth Valley Studios", icon: <Building2 size={16} strokeWidth={1.7} />, active: true },
          ]}
          collapsed={collapsed}
          onToggleCollapsed={() => setCollapsed((v) => !v)}
        />
      </div>
    )
  },
}
