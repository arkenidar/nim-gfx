# examples/hello.nim — nim-gfx smoke test.
#
# Opens a window, draws a few primitives, and closes on Escape or the window ✕.
# Responsive: the logical canvas (and layout) follow the window orientation —
# landscape 640x480, portrait 480x640 — re-applied on every resize/rotation.
# Build:  nim c -r examples/hello.nim   (--smoke: one frame, then exit)

import std/options
import std/os
import gfx

type
  Layout = object
    logW, logH: float
    rectX, rectY, rectW, rectH: float
    circX, circY, circR: float
    dotX, dotY, dotR: float
    lineX1, lineY1, lineX2, lineY2: float
    rrX, rrY, rrW, rrH: float

proc layoutFor(portrait: bool): Layout =
  if portrait:
    Layout(logW: 480, logH: 640,
      rectX: 60, rectY: 60, rectW: 180, rectH: 120,
      circX: 240, circY: 300, circR: 150,
      dotX: 400, dotY: 180, dotR: 50,
      lineX1: 60, lineY1: 540, lineX2: 420, lineY2: 540,
      rrX: 60, rrY: 380, rrW: 240, rrH: 140)
  else:
    Layout(logW: 640, logH: 480,
      rectX: 40, rectY: 40, rectW: 120, rectH: 80,
      circX: 320, circY: 240, circR: 120,
      dotX: 500, dotY: 120, dotR: 40,
      lineX1: 40, lineY1: 400, lineX2: 600, lineY2: 400,
      rrX: 420, rrY: 320, rrW: 160, rrH: 90)

proc pickLayout(win: Window): Layout =
  let (w, h) = windowSize(win)
  layoutFor(h > w)

proc main() =
  let (win, ren) = openWindow("nim-gfx hello", 640, 480)
  let smoke = paramCount() >= 1 and paramStr(1) == "--smoke"

  var layout = pickLayout(win)
  setLogicalSize(ren, layout.logW, layout.logH)

  var running = true
  while running:
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
      of evResize:
        layout = pickLayout(win)
        setLogicalSize(ren, layout.logW, layout.logH)
      else:
        discard

    clear(ren, gray(24))
    fillRect(ren, layout.rectX, layout.rectY, layout.rectW, layout.rectH, rgb(90, 140, 255))
    drawCircleOutline(ren, layout.circX, layout.circY, layout.circR, rgb(255, 200, 60))
    drawCircle(ren, layout.dotX, layout.dotY, layout.dotR, rgb(255, 80, 80))
    drawLine(ren, layout.lineX1, layout.lineY1, layout.lineX2, layout.lineY2, rgb(120, 220, 120))
    roundedRect(ren, layout.rrX, layout.rrY, layout.rrW, layout.rrH, 20, rgb(200, 120, 255))
    present(ren)
    if smoke:
      running = false

  close(win, ren)
  shutdown()

main()
