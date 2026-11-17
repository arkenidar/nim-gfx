# gfx.nim — nim-gfx public API.
#
# This is the ONLY module other packages should import. It is a small,
# backend-agnostic graphics facade: colors, a window + renderer, drawing
# primitives, and input events. The concrete backend is selected at compile
# time:
#
#   default      -> SDL3 renderer backend (gfx_sdl.nim)
#   -d:useCairo  -> Cairo software backend (gfx_cairo.nim; not implemented yet)
#
# All coordinates are window pixels.

import std/options
import std/math

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
    evMouseDown, evMouseUp, evMouseMotion, evTextInput

  Event* = object
    kind*: EventKind
    key*: Key
    button*: Button
    mouseX*, mouseY*: int
    text*: string

proc rgb*(r, g, b: uint8, a: uint8 = 255): Color {.inline.} =
  Color(r: r, g: g, b: b, a: a)

proc black*(a: uint8 = 255): Color {.inline.} = rgb(0, 0, 0, a)
proc white*(a: uint8 = 255): Color {.inline.} = rgb(255, 255, 255, a)
proc gray*(v: uint8, a: uint8 = 255): Color {.inline.} = rgb(v, v, v, a)

when defined(useCairo):
  include gfx_cairo
else:
  include gfx_sdl
