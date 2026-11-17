# gfx_sdl.nim — SDL3 renderer backend for nim-gfx.
#
# Implements the public procs of the gfx facade on top of the raw sdl3.nim
# bindings. This file is `include`d by gfx.nim, so it must NOT import gfx.nim
# itself: the public types (Color, Window, Renderer, Event, ...) and the
# `std/options` import are already in scope.

import ./sdl3

const PI = 3.14159265358979323846

proc openWindow*(title: string; w, h: int): (Window, Renderer) =
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
  (cast[Window](win), cast[Renderer](ren))

proc close*(w: Window; r: Renderer) =
  if r != nil: SDL_DestroyRenderer(cast[ptr SDL_Renderer](r))
  if w != nil: SDL_DestroyWindow(cast[ptr SDL_Window](w))

proc shutdown*() =
  SDL_Quit()

proc setColor(r: Renderer; c: Color) =
  discard SDL_SetRenderDrawColor(cast[ptr SDL_Renderer](r), c.r, c.g, c.b, c.a)

proc clear*(r: Renderer; c: Color) =
  setColor(r, c)
  discard SDL_RenderClear(cast[ptr SDL_Renderer](r))

proc fillRect*(r: Renderer; x, y, w, h: float; c: Color) =
  setColor(r, c)
  var rect = SDL_FRect(x: cfloat(x), y: cfloat(y), w: cfloat(w), h: cfloat(h))
  discard SDL_RenderFillRect(cast[ptr SDL_Renderer](r), addr rect)

proc drawLine*(r: Renderer; x1, y1, x2, y2: float; c: Color) =
  setColor(r, c)
  discard SDL_RenderLine(cast[ptr SDL_Renderer](r),
    cfloat(x1), cfloat(y1), cfloat(x2), cfloat(y2))

proc drawCircle*(r: Renderer; cx, cy, radius: float; c: Color) =
  # Filled circle via horizontal scanlines (SDL3 core has no circle primitive).
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
  discard SDL_RenderPresent(cast[ptr SDL_Renderer](r))

proc ticks*(): int =
  int(SDL_GetTicks())

proc toKey(raw: uint32): Key =
  case raw
  of SDLK_BACKSPACE: return keyBackspace
  of SDLK_TAB:       return keyTab
  of SDLK_RETURN:    return keyEnter
  of SDLK_ESCAPE:    return keyEscape
  of SDLK_SPACE:     return keySpace
  of SDLK_DELETE:    return keyDelete
  of SDLK_LEFT:      return keyLeft
  of SDLK_RIGHT:     return keyRight
  of SDLK_UP:        return keyUp
  of SDLK_DOWN:      return keyDown
  of SDLK_HOME:      return keyHome
  of SDLK_END:       return keyEnd
  else:              discard
  if raw >= 0x61'u32 and raw <= 0x7a'u32:
    return Key(ord(keyA) + int(raw - 0x61'u32))
  if raw >= 0x30'u32 and raw <= 0x39'u32:
    return Key(ord(key0) + int(raw - 0x30'u32))
  return keyNone

proc toButton(b: uint8): Button =
  case b
  of SDL_BUTTON_LEFT:   return btnLeft
  of SDL_BUTTON_MIDDLE: return btnMiddle
  of SDL_BUTTON_RIGHT:  return btnRight
  else:                 return btnNone

proc pollEvent*(): Option[Event] =
  while true:
    var e: SDL_Event
    if not SDL_PollEvent(addr e):
      return none(Event)
    case e.typeVal
    of SDL_EVENT_QUIT, SDL_EVENT_WINDOW_CLOSE_REQUESTED:
      return some(Event(kind: evQuit))
    of SDL_EVENT_KEY_DOWN:
      return some(Event(kind: evKeyDown, key: toKey(e.key.key)))
    of SDL_EVENT_KEY_UP:
      return some(Event(kind: evKeyUp, key: toKey(e.key.key)))
    of SDL_EVENT_TEXT_INPUT:
      var text = ""
      if e.text.text != nil:
        text = $cast[cstring](e.text.text)
      return some(Event(kind: evTextInput, text: text))
    of SDL_EVENT_MOUSE_MOTION:
      return some(Event(kind: evMouseMotion,
        mouseX: int(e.motion.x), mouseY: int(e.motion.y)))
    of SDL_EVENT_MOUSE_BUTTON_DOWN:
      return some(Event(kind: evMouseDown, button: toButton(e.button.button),
        mouseX: int(e.button.x), mouseY: int(e.button.y)))
    of SDL_EVENT_MOUSE_BUTTON_UP:
      return some(Event(kind: evMouseUp, button: toButton(e.button.button),
        mouseX: int(e.button.x), mouseY: int(e.button.y)))
    else:
      discard  # uninteresting event; keep draining
