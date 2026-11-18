# examples/hello.nim — nim-gfx smoke test.
#
# Opens a window, draws a few primitives, and closes on Escape or the window ✕.
# Build:  nim c -r -d:useSdl3 examples/hello.nim   (or -d:useSdl2)

import std/options
import gfx

const
  WinW = 640
  WinH = 480

proc main() =
  let (win, ren) = openWindow("nim-gfx hello", WinW, WinH)

  var running = true
  while running:
    # drain all pending input
    while true:
      let maybe = pollEvent()
      if maybe.isNone:
        break
      let e = maybe.get
      case e.kind
      of evQuit:
        running = false
      of evKeyDown:
        if e.key == keyEscape:
          running = false
      else:
        discard

    clear(ren, gray(24))

    fillRect(ren, 40, 40, 120, 80, rgb(90, 140, 255))         # filled rect
    drawCircleOutline(ren, 320, 240, 120, rgb(255, 200, 60))  # outline circle
    drawCircle(ren, 500, 120, 40, rgb(255, 80, 80))           # filled circle
    drawLine(ren, 40, 400, 600, 400, rgb(120, 220, 120))      # line
    roundedRect(ren, 420, 320, 160, 90, 20, rgb(200, 120, 255))  # rounded rect

    present(ren)

  close(win, ren)
  shutdown()

main()
