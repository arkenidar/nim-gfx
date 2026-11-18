# gfx_sdl2.nim — SDL2 renderer backend for nim-gfx.
#
# Implements the public procs of the gfx facade on top of the raw sdl2.nim
# bindings. This file is `include`d by gfx.nim, so it must NOT import gfx.nim
# itself: the public types (Color, Window, Renderer, Event, ...) and the
# `std/options` import are already in scope.

import ./sdl2
import std/math
include sdl2_events  # pollEvent*, toKey, toButton (shared with the Cairo-on-SDL2 backend)

const PI = 3.14159265358979323846

proc openWindow*(title: string; w, h: int): (Window, Renderer) =
  let (win, ren) = initSdl2Window(title, w, h)
  (cast[Window](win), cast[Renderer](ren))

proc close*(w: Window; r: Renderer) =
  if r != nil: SDL_DestroyRenderer(cast[ptr SDL_Renderer](r))
  if w != nil: SDL_DestroyWindow(cast[ptr SDL_Window](w))

proc shutdown*() =
  sdl2Shutdown()

proc setColor(r: Renderer; c: Color) =
  discard SDL_SetRenderDrawColor(cast[ptr SDL_Renderer](r), c.r, c.g, c.b, c.a)

proc clear*(r: Renderer; c: Color) =
  setColor(r, c)
  discard SDL_RenderClear(cast[ptr SDL_Renderer](r))

proc fillRect*(r: Renderer; x, y, w, h: float; c: Color) =
  setColor(r, c)
  var rect = SDL_FRect(x: cfloat(x), y: cfloat(y), w: cfloat(w), h: cfloat(h))
  discard SDL_RenderFillRectF(cast[ptr SDL_Renderer](r), addr rect)

proc drawLine*(r: Renderer; x1, y1, x2, y2: float; c: Color) =
  setColor(r, c)
  discard SDL_RenderDrawLineF(cast[ptr SDL_Renderer](r),
    cfloat(x1), cfloat(y1), cfloat(x2), cfloat(y2))

proc drawCircle*(r: Renderer; cx, cy, radius: float; c: Color) =
  # Filled circle via horizontal scanlines (SDL2 core has no circle primitive).
  var y = -radius
  while y <= radius:
    let half = sqrt(radius * radius - y * y)
    fillRect(r, cx - half, cy + y, 2.0 * half, 1.0, c)
    y += 1.0

proc drawCircleOutline*(r: Renderer; cx, cy, radius: float; c: Color) =
  const segments = 64
  for i in 0 ..< segments:
    let a0 = 2.0 * PI * float(i) / float(segments)
    let a1 = 2.0 * PI * float(i + 1) / float(segments)
    drawLine(r,
      cx + radius * cos(a0), cy + radius * sin(a0),
      cx + radius * cos(a1), cy + radius * sin(a1), c)

proc roundedRect*(r: Renderer; x, y, w, h, radius: float; c: Color) =
  let rad = min(radius, min(w, h) / 2.0)
  if rad <= 0.0:
    fillRect(r, x, y, w, h, c)
    return
  var yy = 0.0
  while yy < h:
    var inset = 0.0
    if yy < rad:
      let dy = rad - yy
      inset = rad - sqrt(rad * rad - dy * dy)
    elif yy > h - rad:
      let dy = yy - (h - rad)
      inset = rad - sqrt(rad * rad - dy * dy)
    fillRect(r, x + inset, y + yy, w - 2.0 * inset, 1.0, c)
    yy += 1.0

proc present*(r: Renderer) =
  SDL_RenderPresent(cast[ptr SDL_Renderer](r))

proc ticks*(): int =
  sdl2Ticks()
