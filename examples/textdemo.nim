# examples/textdemo.nim — visual demo: Pango text + Cairo primitives.
#
# Build & run:  nim c -r -d:useSdl3 -d:useCairo examples/textdemo.nim
#               (Esc or window X to quit)

import std/options
import gfx

const WinW = 640
const WinH = 480

proc main() =
  let (win, ren) = openWindow("nim-gfx text demo", WinW, WinH)

  var running = true
  while running:
    while true:
      let ev = pollEvent()
      if ev.isNone: break
      case ev.get.kind
      of evQuit: running = false
      of evKeyDown:
        if ev.get.key == keyEscape: running = false
      else: discard

    clear(ren, gray(22))

    # single-line text at various sizes
    drawText(ren, 24, 24, "nim-gfx + Pango text", white(), 30)
    drawText(ren, 24, 74, "small (14)", rgb(120, 200, 255), 14)
    drawText(ren, 24, 100, "big (44)", rgb(255, 180, 60), 44)

    # wrapped text inside a bordered box
    let boxX = 24.0
    let boxY = 170.0
    let boxW = 300.0
    roundedRect(ren, boxX, boxY, boxW, 110, 8, gray(40))
    drawTextWrapped(ren, boxX + 12, boxY + 10, boxW - 24,
      "Pango wraps this paragraph to the box width — no manual word breaking.",
      rgb(210, 220, 255), 16)

    # anti-aliased primitives
    drawCircle(ren, 500, 120, 46, rgb(255, 90, 90))
    drawCircleOutline(ren, 500, 250, 58, rgb(120, 220, 120))
    roundedRect(ren, 420, 350, 180, 90, 20, rgb(200, 120, 255))
    drawText(ren, 440, 385, "rounded rect", white(), 16)

    present(ren)

  close(win, ren)
  shutdown()

main()
