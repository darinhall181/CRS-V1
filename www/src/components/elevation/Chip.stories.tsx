import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { SlidersHorizontal } from "lucide-react"
import { Chip } from "./Chip"

const meta: Meta<typeof Chip> = {
  title: "Elevation Kit/Chip",
  component: Chip,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof Chip>

export const Variants: Story = {
  render: () => (
    <div className="flex items-center gap-2">
      <Chip icon={<SlidersHorizontal size={12} />}>Filters</Chip>
      <Chip>Prep bays</Chip>
      <Chip variant="selected">Full package in stock</Chip>
      <Chip variant="disabled">Delivers to set</Chip>
    </div>
  ),
}

export const Focus: Story = {
  render: () => <Chip autoFocus>Focused</Chip>,
}
