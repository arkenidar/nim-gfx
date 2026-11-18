# gfx.nim — nim-gfx public API.
#
# This is the ONLY module other packages should import. It is a small,
# backend-agnostic graphics facade: colors, a window + renderer, drawing
# primitives, and input events. The concrete backend is selected at compile
# time:
#
#   -d:useSdl3             -> SDL3 renderer backend
#   -d:useSdl2             -> SDL2 renderer backend
#   -d:useSdl3 -d:useCairo -> Cairo on SDL3
#   -d:useSdl2 -d:useCairo -> Cairo on SDL2
#   (no backend flag is a compile error — there is no default)
#
# All coordinates are window pixels.

import std/options

type
  Color* = object
    r*, g*, b*, a*: uint8

  Window* = ptr object
  Renderer* = ptr object

  Key* = enum
    keyNone,
    keyBackspace, keyTab, keyEnter, keyEscape, keySpace, keyDelete,
    keyLeft, keyRight, keyUp, keyDown, keyHome, keyEnd,
    keyA, keyB, keyC, keyD, keyE, keyF, keyG, keyH, keyI, keyJ, keyK, keyL,
    keyM, keyN, keyO, keyP, keyQ, keyR, keyS, keyT, keyU, keyV, keyW, keyX,
    keyY, keyZ,
    key0, key1, key2, key3, key4, key5, key6, key7, key8, key9

  Button* = enum
    btnNone, btnLeft, btnMiddle, btnRight

  EventKind* = enum
    evNone, evQuit, evKeyDown, evKeyUp,
    evMouseDown, evMouseUp, evMouseMotion, evMouseWheel, evTextInput,
    evFingerDown, evFingerUp, evFingerMotion, evResize

  Event* = object
    kind*: EventKind
    key*: Key
    button*: Button
    mouseX*, mouseY*: int
    wheelX*, wheelY*: int
    text*: string
    fingerId*: int64
    fingerX*, fingerY*, fingerDx*, fingerDy*, pressure*: float
    resizeW*, resizeH*: int

proc rgb*(r, g, b: uint8, a: uint8 = 255): Color {.inline.} =
  Color(r: r, g: g, b: b, a: a)

proc black*(a: uint8 = 255): Color {.inline.} = rgb(0, 0, 0, a)
proc white*(a: uint8 = 255): Color {.inline.} = rgb(255, 255, 255, a)
proc gray*(v: uint8, a: uint8 = 255): Color {.inline.} = rgb(v, v, v, a)

# --- logical coordinate system (shared by all backends) ---
# gLogW/gLogH = logical canvas size (0 = not set: draw/input in window pixels).
# gWinW/gWinH = current window size (set by openWindow, updated on resize).
var gLogW = 0.0
var gLogH = 0.0
var gWinW = 0
var gWinH = 0

proc toLogical*(x, y: float): (float, float) =
  ## Inverse of the letterbox transform: window pixel -> logical coordinate.
  if gLogW <= 0.0 or gLogH <= 0.0 or gWinW <= 0 or gWinH <= 0:
    return (x, y)
  let scale = min(float(gWinW) / gLogW, float(gWinH) / gLogH)
  let offX = (float(gWinW) - gLogW * scale) / 2.0
  let offY = (float(gWinH) - gLogH * scale) / 2.0
  ((x - offX) / scale, (y - offY) / scale)

when defined(useCairo):
  when defined(useSdl2):
    include gfx_cairo_sdl2
  elif defined(useSdl3):
    include gfx_cairo_sdl3
  else:
    {.error: "gfx: -d:useCairo needs a shell — also pass -d:useSdl3 or -d:useSdl2".}
elif defined(useSdl2):
  include gfx_sdl2
elif defined(useSdl3):
  include gfx_sdl3
else:
  {.error: "gfx: no backend selected — pass -d:useSdl3 or -d:useSdl2 (optionally -d:useCairo)".}
