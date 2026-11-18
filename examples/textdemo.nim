# examples/textdemo.nim — visual demo: fixed canvas + letterbox + picking + text.
#
# Build & run:  nim c -r -d:useSdl3 -d:useCairo examples/textdemo.nim
#               (Esc or window X to quit; F toggles fullscreen)
#
# One fixed logical canvas (640x480), letterboxed into the window (rememe's
# model). Resizing the window changes the bars, never the content size or shape.

import std/options
import gfx
import ui/events

const LogW = 640.0
const LogH = 480.0
const circle = (cx: 180.0, cy: 220.0, r: 90.0)
const box = (x: 380.0, y: 150.0, w: 220.0, h: 130.0)

proc main() =
  let (win, ren) = openWindow("nim-gfx demo", 640, 480)
  setLogicalSize(ren, LogW, LogH)

  var msg = "click/tap the circle or the box"
  var full = false
  var running = true
  while running:
    while true:
      let maybe = pollEvent()
      if maybe.isNone: break
      let e = maybe.get
      case e.kind
      of evQuit: running = false
      of evKeyDown:
        case e.key
        of keyEscape: running = false
        of keyF:
          full = not full
          setFullscreen(win, full)
        else: discard
      of evMouseDown, evFingerDown:
        let x = if e.kind == evFingerDown: e.fingerX else: float(e.mouseX)
        let y = if e.kind == evFingerDown: e.fingerY else: float(e.mouseY)
        if hitCircle(x, y, circle.cx, circle.cy, circle.r): msg = "picked the CIRCLE"
        elif hitRoundedRect(x, y, box.x, box.y, box.w, box.h, 22.0): msg = "picked the ROUNDED BOX"
        else: msg = "picked nothing at (" & $int(x) & ", " & $int(y) & ")"
      of evResize:
        let (w, h) = windowSize(win)
        msg = "resized to " & $w & "x" & $h
      else: discard

    clear(ren, gray(22))
    drawCircle(ren, circle.cx, circle.cy, circle.r, rgb(255, 90, 90))
    roundedRect(ren, box.x, box.y, box.w, box.h, 22, rgb(90, 140, 255))
    drawText(ren, box.x + 18, box.y + 18, "rounded box", white(), 16)
    drawText(ren, 20, 20, msg, white(), 18)
    drawText(ren, 20, 46, "fixed 640x480 canvas, letterboxed (F = fullscreen)", rgb(150, 200, 150), 14)
    drawTextWrapped(ren, 20, 400, 600,
      "Pango text: single line and wrapped paragraph, rendered crisp at the window native resolution.",
      rgb(210, 220, 255), 15)
    present(ren)

  close(win, ren)
  shutdown()

main()
