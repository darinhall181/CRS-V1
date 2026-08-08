import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { TimelineRow } from "./TimelineRow"

const meta: Meta<typeof TimelineRow> = {
  title: "Elevation Kit/TimelineRow",
  component: TimelineRow,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof TimelineRow>

export const Sequence: Story = {
  render: () => (
    <div style={{ width: 420 }}>
      <TimelineRow weekday="Fri" day={28} title="Prep day — check & build" subtitle="Bay 3 reserved · after 9:00 AM" />
      <TimelineRow
        weekday="Mon"
        day={31}
        title="Wrap & return"
        subtitle="Before 12:00 PM · late fee $180/day"
        showConnector={false}
      />
    </div>
  ),
}
