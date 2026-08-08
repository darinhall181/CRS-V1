import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { SectionHeader } from "./SectionHeader"

const meta: Meta<typeof SectionHeader> = {
  title: "Elevation Kit/SectionHeader",
  component: SectionHeader,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof SectionHeader>

export const AtStart: Story = {
  args: { title: "Services for your shoot", canGoPrev: false, canGoNext: true },
  render: (args) => (
    <div style={{ width: 420 }}>
      <SectionHeader {...args} />
    </div>
  ),
}

export const MidList: Story = {
  args: { title: "Services for your shoot", canGoPrev: true, canGoNext: true },
  render: (args) => (
    <div style={{ width: 420 }}>
      <SectionHeader {...args} />
    </div>
  ),
}
