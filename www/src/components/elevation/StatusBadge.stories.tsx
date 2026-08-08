import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { Check } from "lucide-react"
import { StatusBadge } from "./StatusBadge"

const meta: Meta<typeof StatusBadge> = {
  title: "Elevation Kit/StatusBadge",
  component: StatusBadge,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof StatusBadge>

// DP Profile — Packages & quotes table status column.
export const PackageStatusTable: Story = {
  render: () => (
    <div className="flex items-center gap-2">
      <StatusBadge tone="success">Confirmed</StatusBadge>
      <StatusBadge tone="info">Quoted</StatusBadge>
      <StatusBadge tone="neutral">Draft</StatusBadge>
      <StatusBadge tone="neutral">Returned</StatusBadge>
    </div>
  ),
}

// DP Profile — identity header "Verified DP" badge (icon, no dot).
export const WithIcon: Story = {
  render: () => (
    <StatusBadge tone="info" icon={<Check size={11} strokeWidth={2.4} />}>
      Verified DP
    </StatusBadge>
  ),
}

// RFQ — line-item status cell + hold-expiry line: dot carries the tone,
// label text stays neutral.
export const DotRow: Story = {
  render: () => (
    <div className="flex flex-col items-start gap-2">
      <StatusBadge tone="warning" variant="dot">
        2 confirmed, 1 pending
      </StatusBadge>
      <StatusBadge tone="success" variant="dot">
        Confirmed
      </StatusBadge>
      <StatusBadge tone="warning" variant="dot">
        Hold expires in 46 hrs
      </StatusBadge>
    </div>
  ),
}
