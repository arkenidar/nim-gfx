# pango.nim — raw Pango (pango-cairo) FFI subset for nim-gfx text.
#
# Pango is Cairo's text-layout engine: single-line and wrapped layout,
# measurement, and (later) cursor positioning. Link dynamically (LGPL).
# The backends set the context resolution to 72 DPI so 1 Pango unit == 1 pixel.

import ./cairo

const PANGO_SCALE* = 1024

type
  PangoContext* = object
  PangoLayout* = object
  PangoFontDescription* = object

proc pango_cairo_create_layout*(cr: ptr cairo_t): ptr PangoLayout {.importc, cdecl.}
proc pango_cairo_show_layout*(cr: ptr cairo_t; layout: ptr PangoLayout) {.importc, cdecl.}
proc pango_cairo_context_set_resolution*(context: ptr PangoContext; dpi: cdouble) {.importc, cdecl.}
proc pango_layout_get_context*(layout: ptr PangoLayout): ptr PangoContext {.importc, cdecl.}
proc pango_layout_set_text*(layout: ptr PangoLayout; text: cstring; length: cint) {.importc, cdecl.}
proc pango_layout_set_width*(layout: ptr PangoLayout; width: cint) {.importc, cdecl.}
proc pango_layout_get_pixel_size*(layout: ptr PangoLayout; width, height: ptr cint) {.importc, cdecl.}
proc pango_layout_set_font_description*(layout: ptr PangoLayout; desc: ptr PangoFontDescription) {.importc, cdecl.}
proc pango_font_description_new*(): ptr PangoFontDescription {.importc, cdecl.}
proc pango_font_description_set_family*(desc: ptr PangoFontDescription; family: cstring) {.importc, cdecl.}
proc pango_font_description_set_size*(desc: ptr PangoFontDescription; size: cint) {.importc, cdecl.}
proc pango_font_description_free*(desc: ptr PangoFontDescription) {.importc, cdecl.}
proc g_object_unref*(obj: pointer) {.importc, cdecl.}

{.passL: "-lpangocairo-1.0 -lpango-1.0 -lgobject-2.0 -lglib-2.0".}
