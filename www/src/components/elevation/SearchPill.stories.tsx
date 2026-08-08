import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { SearchPill } from "./SearchPill"

const meta: Meta<typeof SearchPill> = {
  title: "Elevation Kit/SearchPill",
  component: SearchPill,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof SearchPill>

export const Default: Story = {
  render: () => (
    <SearchPill
      segments={[
        { label: "Gear", value: "ALEXA 35 package" },
        { label: "Dates", value: "Aug 28 – 31" },
        { label: "Rental house", value: "Any", placeholder: true },
      ]}
    />
  ),
}
