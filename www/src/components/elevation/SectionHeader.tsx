import { ChevronLeft, ChevronRight } from "lucide-react"
import { IconButton } from "./IconButton"

export interface SectionHeaderProps {
  title: string
  onPrev?: () => void
  onNext?: () => void
  canGoPrev?: boolean
  canGoNext?: boolean
}

// Elevation Kit — SectionHeader/pager: 15px/500 heading + an IconButton/circle
// pair (32px, pager tone), back disabled at the start of the list.
export function SectionHeader({ title, onPrev, onNext, canGoPrev = false, canGoNext = true }: SectionHeaderProps) {
  return (
    <div className="flex items-center justify-between">
      <h3 className="m-0 text-[15px] font-medium">{title}</h3>
      <div className="flex gap-2">
        <IconButton
          size={32}
          icon={<ChevronLeft size={12} strokeWidth={2.2} />}
          aria-label={`Previous ${title}`}
          onClick={onPrev}
          disabled={!canGoPrev}
        />
        <IconButton
          size={32}
          icon={<ChevronRight size={12} strokeWidth={2.2} />}
          aria-label={`Next ${title}`}
          onClick={onNext}
          disabled={!canGoNext}
        />
      </div>
    </div>
  )
}
