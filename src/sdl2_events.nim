# sdl2_events.nim — shared SDL2 -> gfx facade input translation.
#
# This file is `include`d by the SDL2 backends (gfx_sdl2.nim / gfx_cairo_sdl2.nim),
# so the facade types (Event, Key, Button) and the `std/options` import are
# already in scope.

import ./sdl2

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
    if SDL_PollEvent(addr e) == 0:
      return none(Event)
    case e.typeVal
    of SDL_EVENT_QUIT:
      return some(Event(kind: evQuit))
    of SDL_EVENT_WINDOW:
      if e.window.event == SDL_WINDOWEVENT_CLOSE:
        return some(Event(kind: evQuit))
    of SDL_EVENT_KEY_DOWN:
      return some(Event(kind: evKeyDown, key: toKey(uint32(e.key.keysym.sym))))
    of SDL_EVENT_KEY_UP:
      return some(Event(kind: evKeyUp, key: toKey(uint32(e.key.keysym.sym))))
    of SDL_EVENT_TEXT_INPUT:
      var text = ""
      for i in 0 ..< SDL_TEXTINPUTEVENT_TEXT_SIZE:
        let ch = e.text.text[i]
        if ch == '\0': break
        text.add(ch)
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
