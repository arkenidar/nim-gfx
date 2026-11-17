# cairo.nim — raw libcairo FFI subset for nim-gfx's Cairo backend.
#
# Binding layer only: plain `importc` declarations and constants. Link libcairo
# dynamically (LGPL-2.1/MPL-1.1 friendly).

const
  CAIRO_FORMAT_ARGB32*   = 0'i32
  CAIRO_OPERATOR_CLEAR*  = 0'i32
  CAIRO_OPERATOR_SOURCE* = 1'i32
  CAIRO_OPERATOR_OVER*   = 2'i32
  CAIRO_LINE_CAP_BUTT*   = 0'i32
  CAIRO_LINE_CAP_ROUND*  = 1'i32

type
  cairo_t*         = object
  cairo_surface_t* = object

proc cairo_image_surface_create*(format: cint; width, height: cint): ptr cairo_surface_t {.importc, cdecl.}
proc cairo_image_surface_get_data*(surface: ptr cairo_surface_t): pointer {.importc, cdecl.}
proc cairo_image_surface_get_stride*(surface: ptr cairo_surface_t): cint {.importc, cdecl.}
proc cairo_create*(target: ptr cairo_surface_t): ptr cairo_t {.importc, cdecl.}
proc cairo_destroy*(cr: ptr cairo_t) {.importc, cdecl.}
proc cairo_surface_destroy*(surface: ptr cairo_surface_t) {.importc, cdecl.}
proc cairo_surface_flush*(surface: ptr cairo_surface_t) {.importc, cdecl.}
proc cairo_set_operator*(cr: ptr cairo_t; op: cint) {.importc, cdecl.}
proc cairo_set_source_rgba*(cr: ptr cairo_t; r, g, b, a: cdouble) {.importc, cdecl.}
proc cairo_paint*(cr: ptr cairo_t) {.importc, cdecl.}
proc cairo_rectangle*(cr: ptr cairo_t; x, y, w, h: cdouble) {.importc, cdecl.}
proc cairo_arc*(cr: ptr cairo_t; cx, cy, radius, a1, a2: cdouble) {.importc, cdecl.}
proc cairo_move_to*(cr: ptr cairo_t; x, y: cdouble) {.importc, cdecl.}
proc cairo_line_to*(cr: ptr cairo_t; x, y: cdouble) {.importc, cdecl.}
proc cairo_close_path*(cr: ptr cairo_t) {.importc, cdecl.}
proc cairo_stroke*(cr: ptr cairo_t) {.importc, cdecl.}
proc cairo_fill*(cr: ptr cairo_t) {.importc, cdecl.}
proc cairo_set_line_width*(cr: ptr cairo_t; width: cdouble) {.importc, cdecl.}
proc cairo_set_line_cap*(cr: ptr cairo_t; cap: cint) {.importc, cdecl.}

{.passL: "-lcairo".}

