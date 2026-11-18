# sdl3.nim — raw SDL3 FFI subset used by nim-gfx.
#
# This is a binding layer only: plain `importc` declarations, struct layouts and
# constants. Application code should NOT import this module directly — use
# `gfx` (which routes through a backend) instead.

const
  SDL_INIT_VIDEO* = 0x00000020'u32

  SDL_EVENT_QUIT*                 = 0x00000100'u32
  SDL_EVENT_WINDOW_CLOSE_REQUESTED* = 0x00000210'u32
  SDL_EVENT_KEY_DOWN*             = 0x00000300'u32
  SDL_EVENT_KEY_UP*               = 0x00000301'u32
  SDL_EVENT_TEXT_INPUT*           = 0x00000303'u32
  SDL_EVENT_MOUSE_MOTION*         = 0x00000400'u32
  SDL_EVENT_MOUSE_BUTTON_DOWN*    = 0x00000401'u32
  SDL_EVENT_MOUSE_BUTTON_UP*      = 0x00000402'u32

  # SDL virtual keycodes (SDL_Keycode).
  SDLK_RETURN*     = 0x0000000d'u32
  SDLK_ESCAPE*     = 0x0000001b'u32
  SDLK_BACKSPACE*  = 0x00000008'u32
  SDLK_TAB*        = 0x00000009'u32
  SDLK_SPACE*      = 0x00000020'u32
  SDLK_DELETE*     = 0x0000007f'u32
  SDLK_HOME*       = 0x4000004a'u32
  SDLK_END*        = 0x4000004d'u32
  SDLK_RIGHT*      = 0x4000004f'u32
  SDLK_LEFT*       = 0x40000050'u32
  SDLK_DOWN*       = 0x40000051'u32
  SDLK_UP*         = 0x40000052'u32

  # SDL mouse button indices.
  SDL_BUTTON_LEFT*   = 1'u8
  SDL_BUTTON_MIDDLE* = 2'u8
  SDL_BUTTON_RIGHT*  = 3'u8

  # SDL pixel format / texture access (used by the Cairo backend).
  SDL_PIXELFORMAT_ARGB8888*    = 0x16362004'u32
  SDL_TEXTUREACCESS_STREAMING* = 1'i32

type
  SDL_Window*   = object
  SDL_Renderer* = object
  SDL_Texture*  = object

  SDL_FRect* {.bycopy.} = object
    x*, y*, w*, h*: cfloat

  SDL_KeyboardEvent* {.bycopy.} = object
    typeVal*:   uint32
    reserved*:  uint32
    timestamp*: uint64
    windowID*:  uint32
    which*:     uint32
    scancode*:  int32
    key*:       uint32   # SDL_Keycode
    modVal*:    uint16   # SDL_Keymod
    raw*:       uint16
    down*:      bool
    repeat*:    bool

  SDL_TextInputEvent* {.bycopy.} = object
    typeVal*:   uint32
    reserved*:  uint32
    timestamp*: uint64
    windowID*:  uint32
    text*:      ptr char

  SDL_MouseMotionEvent* {.bycopy.} = object
    typeVal*:   uint32
    reserved*:  uint32
    timestamp*: uint64
    windowID*:  uint32
    which*:     uint32
    state*:     uint32
    x*, y*, xrel*, yrel*: cfloat

  SDL_MouseButtonEvent* {.bycopy.} = object
    typeVal*:   uint32
    reserved*:  uint32
    timestamp*: uint64
    windowID*:  uint32
    which*:     uint32
    button*:    uint8
    down*:      bool
    clicks*:    uint8
    padding*:   uint8
    x*, y*:     cfloat

  # SDL_Event is a C union: all members overlap at offset 0, padded to 128 bytes.
  SDL_Event* {.union, bycopy.} = object
    typeVal*: uint32
    key*:     SDL_KeyboardEvent
    text*:    SDL_TextInputEvent
    motion*:  SDL_MouseMotionEvent
    button*:  SDL_MouseButtonEvent
    padding*: array[128, uint8]

proc SDL_Init*(flags: uint32): bool {.importc, cdecl.}
proc SDL_CreateWindow*(title: cstring; w, h: cint; flags: uint64): ptr SDL_Window {.importc, cdecl.}
proc SDL_CreateRenderer*(window: ptr SDL_Window; name: cstring): ptr SDL_Renderer {.importc, cdecl.}
proc SDL_SetRenderDrawColor*(renderer: ptr SDL_Renderer; r, g, b, a: uint8): bool {.importc, cdecl.}
proc SDL_RenderClear*(renderer: ptr SDL_Renderer): bool {.importc, cdecl.}
proc SDL_RenderFillRect*(renderer: ptr SDL_Renderer; rect: ptr SDL_FRect): bool {.importc, cdecl.}
proc SDL_RenderRect*(renderer: ptr SDL_Renderer; rect: ptr SDL_FRect): bool {.importc, cdecl.}
proc SDL_RenderLine*(renderer: ptr SDL_Renderer; x1, y1, x2, y2: cfloat): bool {.importc, cdecl.}
proc SDL_RenderPresent*(renderer: ptr SDL_Renderer): bool {.importc, cdecl.}
proc SDL_PollEvent*(event: ptr SDL_Event): bool {.importc, cdecl.}
proc SDL_SetWindowTitle*(window: ptr SDL_Window; title: cstring): bool {.importc, cdecl.}
proc SDL_StartTextInput*(window: ptr SDL_Window): bool {.importc, cdecl.}
proc SDL_StopTextInput*(window: ptr SDL_Window): bool {.importc, cdecl.}
proc SDL_GetTicks*(): uint64 {.importc, cdecl.}
proc SDL_DestroyRenderer*(renderer: ptr SDL_Renderer) {.importc, cdecl.}
proc SDL_DestroyWindow*(window: ptr SDL_Window) {.importc, cdecl.}
proc SDL_Quit*() {.importc, cdecl.}
proc SDL_GetError*(): cstring {.importc, cdecl.}
proc SDL_CreateTexture*(renderer: ptr SDL_Renderer; format: uint32; access: cint; w, h: cint): ptr SDL_Texture {.importc, cdecl.}
proc SDL_UpdateTexture*(texture: ptr SDL_Texture; rect, pixels: pointer; pitch: cint): bool {.importc, cdecl.}
proc SDL_RenderTexture*(renderer: ptr SDL_Renderer; texture: ptr SDL_Texture; srcrect, dstrect: pointer): bool {.importc, cdecl.}
proc SDL_DestroyTexture*(texture: ptr SDL_Texture) {.importc, cdecl.}

# --- shared window/input helpers (used by both gfx backends) ---

proc initSdlWindow*(title: string; w, h: int): (ptr SDL_Window, ptr SDL_Renderer) =
  if not SDL_Init(SDL_INIT_VIDEO):
    raise newException(IOError, "SDL_Init failed: " & $SDL_GetError())
  let win = SDL_CreateWindow(title.cstring, cint(w), cint(h), 0'u64)
  if win.isNil:
    SDL_Quit()
    raise newException(IOError, "SDL_CreateWindow failed: " & $SDL_GetError())
  let ren = SDL_CreateRenderer(win, nil)
  if ren.isNil:
    SDL_DestroyWindow(win)
    SDL_Quit()
    raise newException(IOError, "SDL_CreateRenderer failed: " & $SDL_GetError())
  discard SDL_StartTextInput(win)  # otherwise SDL_EVENT_TEXT_INPUT is never sent
  (win, ren)

proc sdlShutdown*() =
  SDL_Quit()

proc sdlTicks*(): int =
  int(SDL_GetTicks())

when defined(windows):
  {.passL: "-Wl,-Bstatic -lSDL3 -Wl,-Bdynamic -lkernel32 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lversion -luuid -ladvapi32 -lsetupapi -lshell32 -ldinput8".}
elif defined(android) or defined(termux):
  {.passL: "-lSDL3 -lm".}
elif defined(linux):
  {.passL: "-L/usr/local/lib -Wl,-Bstatic -lSDL3 -Wl,-Bdynamic -pthread -lm".}
else:
  {.passL: "-L/usr/local/lib -Wl,-rpath,/usr/local/lib -lSDL3".}
