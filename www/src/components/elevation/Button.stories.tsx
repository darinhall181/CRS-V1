import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { Button } from "./Button"

const meta: Meta<typeof Button> = {
  title: "Elevation Kit/Button",
  component: Button,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof Button>

export const Variants: Story = {
  render: () => (
    <div className="flex items-center gap-3">
      <Button variant="primary">Add to package</Button>
      <Button variant="accent">Send quote ↗</Button>
      <Button variant="raised">Getting there</Button>
      <Button variant="ghost">Cancel</Button>
    </div>
  ),
}

export const Disabled: Story = {
  render: () => (
    <div className="flex items-center gap-3">
      <Button variant="primary" disabled>
        Add to package
      </Button>
      <Button variant="accent" disabled>
        Send quote ↗
      </Button>
      <Button variant="raised" disabled>
        Getting there
      </Button>
      <Button variant="ghost" disabled>
        Cancel
      </Button>
    </div>
  ),
}

export const Focus: Story = {
  render: () => <Button variant="primary" autoFocus>Focused</Button>,
}
