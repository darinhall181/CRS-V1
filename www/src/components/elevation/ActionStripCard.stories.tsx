import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { Shield } from "lucide-react"
import { ActionStripCard } from "./ActionStripCard"

const meta: Meta<typeof ActionStripCard> = {
  title: "Elevation Kit/Cards/ActionStripCard",
  component: ActionStripCard,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof ActionStripCard>

export const Default: Story = {
  args: {
    icon: <Shield size={20} strokeWidth={1.8} />,
    title: "Add an insurance certificate",
    subtitle: "Required by this rental house before pickup.",
  },
  render: (args) => (
    <div style={{ width: 420 }}>
      <ActionStripCard {...args} />
    </div>
  ),
}
