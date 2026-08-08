import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { BookingSummaryCard } from "./BookingSummaryCard"

const meta: Meta<typeof BookingSummaryCard> = {
  title: "Elevation Kit/Cards/BookingSummaryCard",
  component: BookingSummaryCard,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof BookingSummaryCard>

export const Default: Story = {
  args: {
    title: "Meridian Camera",
    subtitle: "ALEXA 35 package · 6 items",
    dateLabel: "August 28 – 31",
    rate: "$1,540",
    rateUnit: "/day",
    address: "2834 W Empire Ave, Burbank, CA 91504",
    actionLabel: "Getting there",
  },
  render: (args) => (
    <div style={{ width: 420 }}>
      <BookingSummaryCard {...args} />
    </div>
  ),
}
