# gfx_cairo_sdl2.nim — Cairo software backend on the SDL2 shell (selected with
# -d:useCairo -d:useSdl2).
#
# Draws with Cairo into an in-memory ARGB32 image surface, then blits it into
# the SDL2 window as a texture. This file is `include`d by gfx.nim, so it must
# NOT import gfx.nim itself: the public types are already in scope.

import ./sdl2
import ./cairo
include sdl2_events  # pollEvent*, toKey, toButton

const PI = 3.14159265358979323846

type
  CairoRendererObj = object
    sdlRenderer: ptr SDL_Renderer
    texture: ptr SDL_Texture
    surface: ptr cairo_surface_t
    cr: ptr cairo_t
    width, height: int

proc toR(r: Renderer): ptr CairoRendererObj =
  cast[ptr CairoRendererObj](r)

proc openWindow*(title: string; w, h: int): (Window, Renderer) =
  let (win, ren) = initSdl2Window(title, w, h)
  let tex = SDL_CreateTexture(ren, SDL_PIXELFORMAT_ARGB8888,
    SDL_TEXTUREACCESS_STREAMING, cint(w), cint(h))
  if tex.isNil:
    SDL_DestroyRenderer(ren)
    SDL_DestroyWindow(win)
    sdl2Shutdown()
    raise newException(IOError, "SDL_CreateTexture failed: " & $SDL_GetError())
  let surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, cint(w), cint(h))
  let cr = cairo_create(surface)
  let obj = create(CairoRendererObj)
  obj.sdlRenderer = ren
  obj.texture = tex
  obj.surface = surface
  obj.cr = cr
  obj.width = w
  obj.height = h
  (cast[Window](win), cast[Renderer](obj))

proc close*(w: Window; r: Renderer) =
  let o = toR(r)
  if o != nil:
    if o.cr != nil: cairo_destroy(o.cr)
    if o.surface != nil: cairo_surface_destroy(o.surface)
    if o.texture != nil: SDL_DestroyTexture(o.texture)
    if o.sdlRenderer != nil: SDL_DestroyRenderer(o.sdlRenderer)
    dealloc(cast[pointer](o))
  if w != nil: SDL_DestroyWindow(cast[ptr SDL_Window](w))

proc shutdown*() =
  sdl2Shutdown()

proc setSource(r: Renderer; c: Color) =
  cairo_set_source_rgba(toR(r).cr,
    float(c.r) / 255.0, float(c.g) / 255.0, float(c.b) / 255.0, float(c.a) / 255.0)

proc clear*(r: Renderer; c: Color) =
  let cr = toR(r).cr
  setSource(r, c)
  cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
  cairo_paint(cr)
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER)

proc fillRect*(r: Renderer; x, y, w, h: float; c: Color) =
  let cr = toR(r).cr
  setSource(r, c)
  cairo_rectangle(cr, x, y, w, h)
  cairo_fill(cr)

proc drawLine*(r: Renderer; x1, y1, x2, y2: float; c: Color) =
  let cr = toR(r).cr
  setSource(r, c)
  cairo_set_line_width(cr, 1.0)
  cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
  cairo_move_to(cr, x1, y1)
  cairo_line_to(cr, x2, y2)
  cairo_stroke(cr)

proc drawCircle*(r: Renderer; cx, cy, radius: float; c: Color) =
  let cr = toR(r).cr
  setSource(r, c)
  cairo_arc(cr, cx, cy, radius, 0.0, 2.0 * PI)
  cairo_fill(cr)

proc drawCircleOutline*(r: Renderer; cx, cy, radius: float; c: Color) =
  let cr = toR(r).cr
  setSource(r, c)
  cairo_set_line_width(cr, 1.0)
  cairo_arc(cr, cx, cy, radius, 0.0, 2.0 * PI)
  cairo_stroke(cr)

proc roundedRect*(r: Renderer; x, y, w, h, radius: float; c: Color) =
  let cr = toR(r).cr
  let rad = min(radius, min(w, h) / 2.0)
  setSource(r, c)
  cairo_move_to(cr, x + rad, y)
  cairo_line_to(cr, x + w - rad, y)
  cairo_arc(cr, x + w - rad, y + rad, rad, -PI / 2.0, 0.0)
  cairo_line_to(cr, x + w, y + h - rad)
  cairo_arc(cr, x + w - rad, y + h - rad, rad, 0.0, PI / 2.0)
  cairo_line_to(cr, x + rad, y + h)
  cairo_arc(cr, x + rad, y + h - rad, rad, PI / 2.0, PI)
  cairo_line_to(cr, x, y + rad)
  cairo_arc(cr, x + rad, y + rad, rad, PI, 3.0 * PI / 2.0)
  cairo_close_path(cr)
  cairo_fill(cr)

proc present*(r: Renderer) =
  let o = toR(r)
  cairo_surface_flush(o.surface)
  let pixels = cairo_image_surface_get_data(o.surface)
  let stride = cairo_image_surface_get_stride(o.surface)
  discard SDL_UpdateTexture(o.texture, nil, pixels, cint(stride))
  discard SDL_RenderCopy(o.sdlRenderer, o.texture, nil, nil)
  SDL_RenderPresent(o.sdlRenderer)

proc ticks*(): int =
  sdl2Ticks()
