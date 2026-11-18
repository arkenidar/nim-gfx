# sdl2.nim — raw SDL2 FFI subset used by nim-gfx's SDL2 backend.
#
# Binding layer only: plain `importc` declarations, struct layouts and
# constants. Application code should NOT import this module directly — use
# `gfx` (which routes through a backend) instead.

const
  SDL_INIT_VIDEO* = 0x00000020'u32
  SDL_WINDOW_RESIZABLE* = 0x00000020'u32

  SDL_EVENT_QUIT*            = 0x00000100'u32
  SDL_EVENT_WINDOW*          = 0x00000200'u32
  SDL_EVENT_KEY_DOWN*        = 0x00000300'u32
  SDL_EVENT_KEY_UP*          = 0x00000301'u32
  SDL_EVENT_TEXT_INPUT*      = 0x00000303'u32
  SDL_EVENT_MOUSE_MOTION*    = 0x00000400'u32
  SDL_EVENT_MOUSE_BUTTON_DOWN* = 0x00000401'u32
  SDL_EVENT_MOUSE_BUTTON_UP*   = 0x00000402'u32
  SDL_EVENT_MOUSE_WHEEL*       = 0x00000403'u32
  SDL_EVENT_FINGER_DOWN*       = 0x00000700'u32
  SDL_EVENT_FINGER_UP*         = 0x00000701'u32
  SDL_EVENT_FINGER_MOTION*     = 0x00000702'u32
  SDL_WINDOWEVENT_RESIZED*     = 5'u8

  SDL_WINDOWEVENT_CLOSE* = 14'u8
  SDL_WINDOWPOS_UNDEFINED* = 0x1FFF0000'i32

  # SDL virtual keycodes (SDL_Keycode) — same values as SDL3.
  SDLK_RETURN*    = 0x0000000d'u32
  SDLK_ESCAPE*    = 0x0000001b'u32
  SDLK_BACKSPACE* = 0x00000008'u32
  SDLK_TAB*       = 0x00000009'u32
  SDLK_SPACE*     = 0x00000020'u32
  SDLK_DELETE*    = 0x0000007f'u32
  SDLK_HOME*      = 0x4000004a'u32
  SDLK_END*       = 0x4000004d'u32
  SDLK_RIGHT*     = 0x4000004f'u32
  SDLK_LEFT*      = 0x40000050'u32
  SDLK_DOWN*      = 0x40000051'u32
  SDLK_UP*        = 0x40000052'u32

  SDL_BUTTON_LEFT*   = 1'u8
  SDL_BUTTON_MIDDLE* = 2'u8
  SDL_BUTTON_RIGHT*  = 3'u8

  SDL_TEXTINPUTEVENT_TEXT_SIZE* = 32

  SDL_PIXELFORMAT_ARGB8888*    = 0x16362004'u32
  SDL_TEXTUREACCESS_STREAMING* = 1'i32
  SDL_WINDOW_FULLSCREEN_DESKTOP* = 0x00001001'u32

type
  SDL_Window*   = object
  SDL_Renderer* = object
  SDL_Texture*  = object

  SDL_Rect* {.bycopy.} = object
    x*, y*, w*, h*: cint

  SDL_Keysym* {.bycopy.} = object
    scancode*: int32
    sym*: int32
    modVal*: uint16
    unused*: uint32

  SDL_KeyboardEvent* {.bycopy.} = object
    typeVal*:   uint32
    timestamp*: uint32
    windowID*:  uint32
    state*:     uint8
    repeat*:    uint8
    padding2*:  uint8
    padding3*:  uint8
    keysym*:    SDL_Keysym

  SDL_TextInputEvent* {.bycopy.} = object
    typeVal*:   uint32
    timestamp*: uint32
    windowID*:  uint32
    text*:      array[32, char]

  SDL_MouseMotionEvent* {.bycopy.} = object
    typeVal*:   uint32
    timestamp*: uint32
    windowID*:  uint32
    which*:     uint32
    state*:     uint32
    x*, y*, xrel*, yrel*: int32

  SDL_MouseButtonEvent* {.bycopy.} = object
    typeVal*:   uint32
    timestamp*: uint32
    windowID*:  uint32
    which*:     uint32
    button*:    uint8
    state*:     uint8
    clicks*:    uint8
    padding1*:  uint8
    x*, y*:     int32

  SDL_WindowEvent* {.bycopy.} = object
    typeVal*:   uint32
    timestamp*: uint32
    windowID*:  uint32
    event*:     uint8
    padding1*:  uint8
    padding2*:  uint8
    padding3*:  uint8
    data1*, data2*: int32

  SDL_MouseWheelEvent* {.bycopy.} = object
    typeVal*:   uint32
    timestamp*: uint32
    windowID*:  uint32
    which*:     uint32
    x*, y*:     int32
    direction*: uint32
    preciseX*, preciseY*: cfloat
    mouseX*, mouseY*: int32

  SDL_TouchFingerEvent* {.bycopy.} = object
    typeVal*:   uint32
    timestamp*: uint32
    touchId*:   int64
    fingerId*:  int64
    x*, y*, dx*, dy*, pressure*: cfloat
    windowID*:  uint32

  # SDL_Event is a C union, 56 bytes on 64-bit platforms.
  SDL_Event* {.union, bycopy.} = object
    typeVal*: uint32
    window*:  SDL_WindowEvent
    key*:     SDL_KeyboardEvent
    text*:    SDL_TextInputEvent
    motion*:  SDL_MouseMotionEvent
    button*:  SDL_MouseButtonEvent
    wheel*:   SDL_MouseWheelEvent
    finger*:  SDL_TouchFingerEvent
    padding*: array[56, uint8]

proc SDL_Init*(flags: uint32): cint {.importc, cdecl.}
proc SDL_CreateWindow*(title: cstring; x, y, w, h: cint; flags: uint32): ptr SDL_Window {.importc, cdecl.}
proc SDL_CreateRenderer*(window: ptr SDL_Window; index: cint; flags: uint32): ptr SDL_Renderer {.importc, cdecl.}
proc SDL_RenderCopy*(renderer: ptr SDL_Renderer; texture: ptr SDL_Texture; srcrect, dstrect: ptr SDL_Rect): cint {.importc, cdecl.}
proc SDL_RenderPresent*(renderer: ptr SDL_Renderer) {.importc, cdecl.}
proc SDL_CreateTexture*(renderer: ptr SDL_Renderer; format: uint32; access: cint; w, h: cint): ptr SDL_Texture {.importc, cdecl.}
proc SDL_UpdateTexture*(texture: ptr SDL_Texture; rect: ptr SDL_Rect; pixels: pointer; pitch: cint): cint {.importc, cdecl.}
proc SDL_DestroyTexture*(texture: ptr SDL_Texture) {.importc, cdecl.}
proc SDL_GetWindowSize*(window: ptr SDL_Window; w, h: ptr cint) {.importc, cdecl.}
proc SDL_MaximizeWindow*(window: ptr SDL_Window) {.importc, cdecl.}
proc SDL_SetWindowFullscreen*(window: ptr SDL_Window; flags: uint32): cint {.importc, cdecl.}
proc SDL_PollEvent*(event: ptr SDL_Event): cint {.importc, cdecl.}
proc SDL_StartTextInput*() {.importc, cdecl.}
proc SDL_StopTextInput*() {.importc, cdecl.}
proc SDL_GetTicks*(): uint32 {.importc, cdecl.}
proc SDL_DestroyRenderer*(renderer: ptr SDL_Renderer) {.importc, cdecl.}
proc SDL_DestroyWindow*(window: ptr SDL_Window) {.importc, cdecl.}
proc SDL_Quit*() {.importc, cdecl.}
proc SDL_GetError*(): cstring {.importc, cdecl.}

when defined(windows):
  {.passL: "-lSDL2".}
else:
  {.passL: "-lSDL2 -lm".}

# --- shared helpers (used by the SDL2 and Cairo-on-SDL2 backends) ---

proc initSdl2Window*(title: string; w, h: int): (ptr SDL_Window, ptr SDL_Renderer) =
  if SDL_Init(SDL_INIT_VIDEO) != 0:
    raise newException(IOError, "SDL_Init failed: " & $SDL_GetError())
  let win = SDL_CreateWindow(title.cstring, SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED, cint(w), cint(h), SDL_WINDOW_RESIZABLE)
  if win.isNil:
    SDL_Quit()
    raise newException(IOError, "SDL_CreateWindow failed: " & $SDL_GetError())
  let ren = SDL_CreateRenderer(win, -1, 0'u32)
  if ren.isNil:
    SDL_DestroyWindow(win)
    SDL_Quit()
    raise newException(IOError, "SDL_CreateRenderer failed: " & $SDL_GetError())
  SDL_StartTextInput()  # otherwise SDL_TEXTINPUT is never sent
  (win, ren)

proc sdl2Shutdown*() =
  SDL_Quit()

proc sdl2Ticks*(): int =
  int(SDL_GetTicks())
