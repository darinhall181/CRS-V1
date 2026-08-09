import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { useState } from "react"
import { Switch } from "./Switch"

const meta: Meta<typeof Switch> = {
  title: "Elevation Kit/Switch",
  component: Switch,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof Switch>

// Onboarding — "I own gear I bring to jobs" toggle.
export const Interactive: Story = {
  render: function Render() {
    const [checked, setChecked] = useState(false)
    return <Switch checked={checked} onChange={setChecked} aria-label="I own gear I bring to jobs" />
  },
}

export const States: Story = {
  render: () => (
    <div className="flex items-center gap-4">
      <Switch checked={false} onChange={() => {}} aria-label="Off" />
      <Switch checked={true} onChange={() => {}} aria-label="On" />
    </div>
  ),
}
