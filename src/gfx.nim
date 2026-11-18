# gfx.nim — nim-gfx public API.
#
# This is the ONLY module other packages should import. It is a small graphics
# facade: colors, a window + renderer, drawing primitives, and input events —
# one backend: SDL2 (window/input) + Cairo (drawing) + Pango (text). No
# compile-time backend flags.
#
# Coordinates are logical after setLogicalSize (fixed canvas, letterboxed).

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
# The canvas is always letterboxed (fit, preserve aspect) into the window —
# rememe's model: one fixed canvas, one mapping, no modes.

var gLogW = 0.0
var gLogH = 0.0
var gWinW = 0
var gWinH = 0

proc toLogical*(x, y: float): (float, float) =
  ## Inverse of the letterbox transform: window pixel -> logical coord.
  if gLogW <= 0.0 or gLogH <= 0.0 or gWinW <= 0 or gWinH <= 0:
    return (x, y)
  let s = min(float(gWinW) / gLogW, float(gWinH) / gLogH)
  let offX = (float(gWinW) - gLogW * s) / 2.0
  let offY = (float(gWinH) - gLogH * s) / 2.0
  ((x - offX) / s, (y - offY) / s)

proc setLogicalSize*(r: Renderer; w, h: float) =
  ## Set the fixed logical canvas — rememe's model: one canvas, one mapping,
  ## no modes. Drawn content and input are letterboxed (fit, preserve aspect)
  ## into the window; without this, coordinates are window pixels.
  gLogW = w; gLogH = h

include gfx_cairo_sdl2
