# examples/textdemo.nim — visual demo: responsive canvas + letterbox + picking + text.
#
# Build & run:  nim c -r examples/textdemo.nim   (--smoke: one frame, then exit)
#               (Esc or window X to quit; F toggles fullscreen)
#
# Responsive: the logical canvas follows the window orientation — landscape
# 640x480, portrait 480x640 — re-applied on every resize/rotation. The canvas is
# letterboxed into the window (rememe's model: one mapping, no modes).

import std/options
import std/os
import gfx
import ui/events

type
  Layout = object
    logW, logH: float
    circle: tuple[cx, cy, r: float]
    box: tuple[x, y, w, h: float]

proc layoutFor(portrait: bool): Layout =
  if portrait:
    Layout(logW: 480, logH: 640,
      circle: (cx: 240.0, cy: 200.0, r: 100.0),
      box: (x: 90.0, y: 340.0, w: 300.0, h: 160.0))
  else:
    Layout(logW: 640, logH: 480,
      circle: (cx: 180.0, cy: 220.0, r: 90.0),
      box: (x: 380.0, y: 150.0, w: 220.0, h: 130.0))

proc pickLayout(win: Window): Layout =
  let (w, h) = windowSize(win)
  layoutFor(h > w)

proc main() =
  let (win, ren) = openWindow("nim-gfx demo", 640, 480)
  let smoke = paramCount() >= 1 and paramStr(1) == "--smoke"

  var layout = pickLayout(win)
  setLogicalSize(ren, layout.logW, layout.logH)

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
        if hitCircle(x, y, layout.circle.cx, layout.circle.cy, layout.circle.r):
          msg = "picked the CIRCLE"
        elif hitRoundedRect(x, y, layout.box.x, layout.box.y, layout.box.w, layout.box.h, 22.0):
          msg = "picked the ROUNDED BOX"
        else:
          msg = "picked nothing at (" & $int(x) & ", " & $int(y) & ")"
      of evResize:
        layout = pickLayout(win)
        setLogicalSize(ren, layout.logW, layout.logH)
        msg = "resized: " & (if layout.logW < layout.logH: "portrait" else: "landscape")
      else: discard

    clear(ren, gray(22))
    drawCircle(ren, layout.circle.cx, layout.circle.cy, layout.circle.r, rgb(255, 90, 90))
    roundedRect(ren, layout.box.x, layout.box.y, layout.box.w, layout.box.h, 22, rgb(90, 140, 255))
    drawText(ren, layout.box.x + 18, layout.box.y + 18, "rounded box", white(), 16)
    drawText(ren, 20, 20, msg, white(), 18)
    drawText(ren, 20, 46, "responsive canvas, letterboxed (F = fullscreen)", rgb(150, 200, 150), 14)
    drawTextWrapped(ren, 20, layout.logH - 80, layout.logW - 40,
      "Pango text: single line and wrapped paragraph, rendered crisp at the window native resolution.",
      rgb(210, 220, 255), 15)
    present(ren)
    if smoke:
      running = false

  close(win, ren)
  shutdown()

main()
