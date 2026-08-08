import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { ArrowLeft, ChevronRight, Plus } from "lucide-react"
import { IconButton } from "./IconButton"

const meta: Meta<typeof IconButton> = {
  title: "Elevation Kit/IconButton",
  component: IconButton,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof IconButton>

export const Variants: Story = {
  render: () => (
    <div className="flex items-center gap-3">
      <IconButton shape="circle" tone="pager" icon={<ArrowLeft size={15} />} aria-label="Back" />
      <IconButton shape="circle" tone="control" icon={<ChevronRight size={14} />} aria-label="Next" />
      <IconButton shape="circle" icon={<ChevronRight size={14} />} aria-label="Disabled back" disabled />
      <IconButton shape="square" icon={<Plus size={14} />} aria-label="Add" />
    </div>
  ),
}

export const Disabled: Story = {
  render: () => (
    <div className="flex items-center gap-3">
      <IconButton shape="circle" icon={<ArrowLeft size={15} />} aria-label="Back" disabled />
      <IconButton shape="square" icon={<Plus size={14} />} aria-label="Add" disabled />
    </div>
  ),
}

export const Focus: Story = {
  render: () => (
    <IconButton shape="circle" icon={<Plus size={14} />} aria-label="Add" autoFocus />
  ),
}
