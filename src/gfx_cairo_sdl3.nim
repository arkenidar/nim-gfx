# gfx_cairo_sdl3.nim — Cairo software backend on the SDL3 shell (selected with
# -d:useCairo -d:useSdl3).
#
# Draws with Cairo into an in-memory ARGB32 image surface, then blits it into
# the SDL window as a texture. This file is `include`d by gfx.nim, so it must
# NOT import gfx.nim itself: the public types are already in scope.

import ./sdl3
import ./cairo
import ./pango
include sdl_events  # pollEvent*, toKey, toButton (shared with the SDL3 backend)

const PI = 3.14159265358979323846

type
  CairoRendererObj = object
    sdlRenderer: ptr SDL_Renderer
    texture: ptr SDL_Texture
    surface: ptr cairo_surface_t
    cr: ptr cairo_t
    layout: ptr PangoLayout
    window: ptr SDL_Window
    width, height: int

proc toR(r: Renderer): ptr CairoRendererObj =
  cast[ptr CairoRendererObj](r)

proc openWindow*(title: string; w, h: int): (Window, Renderer) =
  let (win, ren) = initSdlWindow(title, w, h)
  let tex = SDL_CreateTexture(ren, SDL_PIXELFORMAT_ARGB8888,
    SDL_TEXTUREACCESS_STREAMING, cint(w), cint(h))
  if tex.isNil:
    SDL_DestroyRenderer(ren)
    SDL_DestroyWindow(win)
    sdlShutdown()
    raise newException(IOError, "SDL_CreateTexture failed: " & $SDL_GetError())
  let surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, cint(w), cint(h))
  let cr = cairo_create(surface)
  let obj = create(CairoRendererObj)
  obj.sdlRenderer = ren
  obj.texture = tex
  obj.surface = surface
  obj.cr = cr
  obj.window = win
  obj.layout = pango_cairo_create_layout(cr)
  pango_cairo_context_set_resolution(pango_layout_get_context(obj.layout), 72.0)
  obj.width = w
  obj.height = h
  gWinW = w; gWinH = h
  (cast[Window](win), cast[Renderer](obj))

proc close*(w: Window; r: Renderer) =
  let o = toR(r)
  if o != nil:
    if o.layout != nil: g_object_unref(cast[pointer](o.layout))
    if o.cr != nil: cairo_destroy(o.cr)
    if o.surface != nil: cairo_surface_destroy(o.surface)
    if o.texture != nil: SDL_DestroyTexture(o.texture)
    if o.sdlRenderer != nil: SDL_DestroyRenderer(o.sdlRenderer)
    dealloc(cast[pointer](o))
  if w != nil: SDL_DestroyWindow(cast[ptr SDL_Window](w))

proc shutdown*() =
  sdlShutdown()

proc setSource(r: Renderer; c: Color) =
  cairo_set_source_rgba(toR(r).cr,
    float(c.r) / 255.0, float(c.g) / 255.0, float(c.b) / 255.0, float(c.a) / 255.0)

proc clear*(r: Renderer; c: Color) =
  let o = toR(r)
  let cr = o.cr
  setSource(r, c)
  cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
  cairo_identity_matrix(cr)
  cairo_paint(cr)
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
  if gLogW > 0.0 and gLogH > 0.0 and o.width > 0 and o.height > 0:
    if gScaleMode == scaleStretch:
      cairo_scale(cr, float(o.width) / gLogW, float(o.height) / gLogH)
    else:
      let scale = min(float(o.width) / gLogW, float(o.height) / gLogH)
      let offX = (float(o.width) - gLogW * scale) / 2.0
      let offY = (float(o.height) - gLogH * scale) / 2.0
      cairo_translate(cr, offX, offY)
      cairo_scale(cr, scale, scale)

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
  var ww, wh: cint
  discard SDL_GetWindowSize(cast[ptr SDL_Window](o.window), addr ww, addr wh)
  if int(ww) != o.width or int(wh) != o.height:
    if o.cr != nil: cairo_destroy(o.cr)
    if o.surface != nil: cairo_surface_destroy(o.surface)
    if o.texture != nil: SDL_DestroyTexture(o.texture)
    o.texture = SDL_CreateTexture(o.sdlRenderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STREAMING, ww, wh)
    o.surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, ww, wh)
    o.cr = cairo_create(o.surface)
    if o.layout != nil: g_object_unref(cast[pointer](o.layout))
    o.layout = pango_cairo_create_layout(o.cr)
    pango_cairo_context_set_resolution(pango_layout_get_context(o.layout), 72.0)
    o.width = int(ww); o.height = int(wh)
    gWinW = int(ww); gWinH = int(wh)
  cairo_surface_flush(o.surface)
  let pixels = cairo_image_surface_get_data(o.surface)
  let stride = cairo_image_surface_get_stride(o.surface)
  discard SDL_UpdateTexture(o.texture, nil, pixels, stride)
  discard SDL_RenderTexture(o.sdlRenderer, o.texture, nil, nil)
  discard SDL_RenderPresent(o.sdlRenderer)

proc setClipRect*(r: Renderer; x, y, w, h: float) =
  let cr = toR(r).cr
  cairo_rectangle(cr, x, y, w, h)
  cairo_clip(cr)

proc resetClip*(r: Renderer) =
  cairo_reset_clip(toR(r).cr)

proc setFont(layout: ptr PangoLayout; size: float; family: string) =
  let desc = pango_font_description_new()
  pango_font_description_set_family(desc, family.cstring)
  pango_font_description_set_size(desc, cint(size * float(PANGO_SCALE)))
  pango_layout_set_font_description(layout, desc)
  pango_font_description_free(desc)

proc drawText*(r: Renderer; x, y: float; text: string; c: Color; size: float = 12.0; family: string = "sans") =
  let cr = toR(r).cr
  let layout = toR(r).layout
  setSource(r, c)
  setFont(layout, size, family)
  pango_layout_set_width(layout, -1)
  pango_layout_set_text(layout, text.cstring, -1)
  cairo_move_to(cr, x, y)
  pango_cairo_show_layout(cr, layout)

proc drawTextWrapped*(r: Renderer; x, y, width: float; text: string; c: Color; size: float = 12.0; family: string = "sans") =
  let cr = toR(r).cr
  let layout = toR(r).layout
  setSource(r, c)
  setFont(layout, size, family)
  pango_layout_set_width(layout, cint(width * float(PANGO_SCALE)))
  pango_layout_set_text(layout, text.cstring, -1)
  cairo_move_to(cr, x, y)
  pango_cairo_show_layout(cr, layout)

proc textSize*(r: Renderer; text: string; size: float = 12.0; family: string = "sans"): (int, int) =
  let layout = toR(r).layout
  setFont(layout, size, family)
  pango_layout_set_width(layout, -1)
  pango_layout_set_text(layout, text.cstring, -1)
  var w, h: cint
  pango_layout_get_pixel_size(layout, addr w, addr h)
  (int(w), int(h))

proc windowSize*(w: Window): (int, int) =
  var ww, wh: cint
  discard SDL_GetWindowSize(cast[ptr SDL_Window](w), addr ww, addr wh)
  (int(ww), int(wh))

proc maximize*(w: Window) =
  discard SDL_MaximizeWindow(cast[ptr SDL_Window](w))

proc setFullscreen*(w: Window; fs: bool) =
  discard SDL_SetWindowFullscreen(cast[ptr SDL_Window](w), fs)

proc setLogicalSize*(r: Renderer; w, h: float; mode: ScaleMode = scaleStretch) =
  gLogW = w; gLogH = h; gScaleMode = mode

proc ticks*(): int =
  sdlTicks()

