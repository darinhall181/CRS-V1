import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { StatCard } from "./StatCard"

const meta: Meta<typeof StatCard> = {
  title: "Elevation Kit/StatCard",
  component: StatCard,
  parameters: { layout: "padded" },
}
export default meta
type Story = StoryObj<typeof StatCard>

// Dashboard — production-workspace 4-up grid.
export const DashboardGrid: Story = {
  render: () => (
    <div className="grid grid-cols-4 gap-4">
      <StatCard label="Packages in progress" value="3" note="1 needs review" />
      <StatCard label="Quotes awaiting response" value="2" note="$79,900 in play" tone="info" />
      <StatCard label="Days until pickup" value="8" unit="days" note="Ridgeline — A-cam" />
      <StatCard label="Needs attention" value="2" tone="warning" note="COI expiring, 1 substitution" />
    </div>
  ),
}

// History — spend/receivables header.
export const HistoryGrid: Story = {
  render: () => (
    <div className="grid grid-cols-4 gap-4">
      <StatCard label="Spend, last 90 days" value="$186,400" note="Across 4 rental houses" />
      <StatCard label="Outstanding invoices" value="$54,950" tone="warning" note="2 invoices, 1 overdue" />
      <StatCard label="Open quotes" value="3" tone="info" note="$101,700 in play" />
      <StatCard label="Rentals in progress" value="2" note="Next return Aug 16" />
    </div>
  ),
}
