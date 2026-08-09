import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { TopBar } from "./TopBar"

const meta: Meta<typeof TopBar> = {
  title: "Elevation Kit/TopBar",
  component: TopBar,
  parameters: { layout: "fullscreen" },
}
export default meta
type Story = StoryObj<typeof TopBar>

const LOGO = <div className="h-[23px] w-[23px] flex-none rounded-[5px] bg-[var(--interactive-default)]" />

const USER_MENU = (
  <div className="flex items-center gap-2">
    <div className="flex h-[36px] w-[36px] items-center justify-center rounded-full bg-[var(--interactive-default)] text-[13px] font-medium text-white">
      DA
    </div>
    <span className="text-[15px] font-medium text-[var(--text-primary)]">Darin</span>
  </div>
)

// Package Builder — full-width bar; a page composes this above a
// SidebarNav + content row so the sidebar starts below it rather than
// hitting the top of the viewport.
export const Default: Story = {
  render: () => (
    <div style={{ height: "220px", background: "var(--bg-base)" }}>
      <TopBar
        logo={LOGO}
        wordmark="Altoscope"
        searchPlaceholder="Search gear, packages, rental houses"
        userMenu={USER_MENU}
      />
    </div>
  ),
}
