import type { Meta, StoryObj } from "@storybook/nextjs-vite"
import { ServiceCard } from "./ServiceCard"

const meta: Meta<typeof ServiceCard> = {
  title: "Elevation Kit/Cards/ServiceCard",
  component: ServiceCard,
  parameters: { layout: "centered" },
}
export default meta
type Story = StoryObj<typeof ServiceCard>

export const Row: Story = {
  render: () => (
    <div className="grid grid-cols-3 gap-4" style={{ width: 620 }}>
      <ServiceCard title="DITs" count={48} availabilityLabel="Aug 28–31" />
      <ServiceCard title="1st ACs" count={112} availabilityLabel="Aug 28–31" />
      <ServiceCard title="Gaffers" count={64} availabilityLabel="Aug 28–31" />
    </div>
  ),
}
