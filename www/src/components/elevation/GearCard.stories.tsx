import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { GearCard } from "./GearCard"

const meta: Meta<typeof GearCard> = {
  title: "Elevation Kit/Cards/GearCard",
  component: GearCard,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof GearCard>

export const Default: Story = {
  args: {
    name: "ARRI ALEXA 35",
    spec: "4.6K Super 35 body",
    rate: "$780",
    rateUnit: "/day",
  },
  render: (args) => (
    <div style={{ width: 220 }}>
      <GearCard {...args} />
    </div>
  ),
}

// T0036 — selected-card treatment: unselected vs. selected side by side.
export const SelectedState: Story = {
  render: () => (
    <div className="flex gap-4">
      <div style={{ width: 220 }}>
        <GearCard name="ARRI ALEXA 35" spec="4.6K Super 35 body" rate="$780" rateUnit="/day" />
      </div>
      <div style={{ width: 220 }}>
        <GearCard name="ARRI ALEXA 35" spec="4.6K Super 35 body" rate="$780" rateUnit="/day" selected />
      </div>
    </div>
  ),
}
