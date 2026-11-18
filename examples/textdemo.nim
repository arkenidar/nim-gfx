# examples/textdemo.nim — visual demo: coordinate scaling + Pango text + picking.
#
# Build & run:  nim c -r -d:useSdl3 -d:useCairo examples/textdemo.nim
#               (Esc or window X to quit)
#
# The window is drawn in a LOGICAL 640x480 space that gfx maps (letterboxed,
# crisp) onto whatever window size you give it. Click/tap the circle or the
# rounded box and it echoes which one you picked — input uses the SAME logical
# space as drawing, so picking matches what you see at any size/orientation.

import std/options
import gfx

const LogW = 640.0
const LogH = 480.0

const circle = (cx: 180.0, cy: 220.0, r: 90.0)
const box = (x: 380.0, y: 150.0, w: 220.0, h: 130.0)

proc inCircle(x, y: float): bool =
  (x - circle.cx) * (x - circle.cx) + (y - circle.cy) * (y - circle.cy) <= circle.r * circle.r

proc inBox(x, y: float): bool =
  x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h

proc main() =
  let (win, ren) = openWindow("nim-gfx coordinate demo", 960, 720)
  maximize(win)
  setLogicalSize(ren, LogW, LogH)

  var msg = "click/tap the circle or the box"
  var running = true
  while running:
    while true:
      let maybe = pollEvent()
      if maybe.isNone: break
      let e = maybe.get
      case e.kind
      of evQuit: running = false
      of evKeyDown:
        if e.key == keyEscape: running = false
      of evMouseDown, evFingerDown:
        let x = if e.kind == evFingerDown: e.fingerX else: float(e.mouseX)
        let y = if e.kind == evFingerDown: e.fingerY else: float(e.mouseY)
        if inCircle(x, y): msg = "picked the CIRCLE"
        elif inBox(x, y): msg = "picked the ROUNDED BOX"
        else: msg = "picked nothing at (" & $int(x) & ", " & $int(y) & ")"
      of evResize:
        let (w, h) = windowSize(win)
        let orient = if w > h: "landscape" else: "portrait"
        msg = "resized to " & $w & "x" & $h & " (" & orient & ")"
      else: discard

    clear(ren, gray(22))

    drawCircle(ren, circle.cx, circle.cy, circle.r, rgb(255, 90, 90))
    roundedRect(ren, box.x, box.y, box.w, box.h, 22, rgb(90, 140, 255))
    drawText(ren, box.x + 18, box.y + 18, "rounded box", white(), 16)

    drawText(ren, 20, 20, msg, white(), 18)
    drawText(ren, 20, 46, "logical " & $int(LogW) & "x" & $int(LogH) & "  ->  window",
      rgb(150, 200, 150), 14)
    drawTextWrapped(ren, 20, 380, 400,
      "Pango text: single line and wrapped paragraph, rendered crisp at the window's native resolution via coordinate scaling.",
      rgb(210, 220, 255), 15)

    present(ren)

  close(win, ren)
  shutdown()

main()
