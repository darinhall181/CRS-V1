import { useState } from "react"
import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { SegmentedToggle } from "./SegmentedToggle"

const meta: Meta<typeof SegmentedToggle> = {
  title: "Elevation Kit/SegmentedToggle",
  component: SegmentedToggle,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof SegmentedToggle>

function Interactive() {
  const [value, setValue] = useState<0 | 1>(0)
  return (
    <SegmentedToggle
      options={["APS-C", "Full frame"]}
      value={value}
      onChange={setValue}
      aria-label="Sensor format"
    />
  )
}

export const Default: Story = {
  render: () => <Interactive />,
}

export const RightSelected: Story = {
  render: () => (
    <SegmentedToggle options={["APS-C", "Full frame"]} value={1} onChange={() => {}} aria-label="Sensor format" />
  ),
}
