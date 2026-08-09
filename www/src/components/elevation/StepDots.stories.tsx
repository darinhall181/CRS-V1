import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { useState } from "react"
import { StepDots } from "./StepDots"

const meta: Meta<typeof StepDots> = {
  title: "Elevation Kit/StepDots",
  component: StepDots,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof StepDots>

const STEPS = ["Log in", "Workspace", "Profession", "Profile", "Working details", "Ready"]

export const Interactive: Story = {
  render: function Render() {
    const [active, setActive] = useState(1)
    return <StepDots steps={STEPS} activeIndex={active} onSelect={setActive} />
  },
}
