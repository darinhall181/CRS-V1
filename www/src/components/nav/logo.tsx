import Image from "next/image"

// h-[23px] w-[23px] forces a true square — the source PNG isn't square
// (1328x1696), and Tailwind's preflight `img { height: auto }` otherwise wins
// over the Image component's height attribute, stretching it to ~29px tall.
// Shared by every TopBar usage (Package Builder's, and (app)'s AppShell) so
// the mark stays pixel-identical across them.
export function AltoscopeLogo() {
  return (
    <Image
      src="/altoscope-mark-white.png"
      alt=""
      width={23}
      height={23}
      className="h-[23px] w-[23px] flex-none object-contain"
    />
  )
}
