import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { StatusBadge } from "./StatusBadge"

const meta: Meta<typeof StatusBadge> = {
  title: "Elevation Kit/StatusBadge",
  component: StatusBadge,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof StatusBadge>

export const Pills: Story = {
  render: () => (
    <div className="flex items-center gap-2">
      <StatusBadge tone="success">Confirmed</StatusBadge>
      <StatusBadge tone="warning">Hold expiring</StatusBadge>
      <StatusBadge tone="info">Sent</StatusBadge>
      <StatusBadge tone="danger">Unavailable</StatusBadge>
      <StatusBadge tone="neutral">Draft</StatusBadge>
    </div>
  ),
}

export const DotOnly: Story = {
  render: () => (
    <div className="flex flex-col items-start gap-2">
      <StatusBadge tone="success" variant="dot">Confirmed</StatusBadge>
      <StatusBadge tone="warning" variant="dot">Substitution</StatusBadge>
      <StatusBadge tone="info" variant="dot">Added by house</StatusBadge>
    </div>
  ),
}
