# nim-gfx

A small, backend-agnostic graphics facade for Nim: a window + renderer, colors,
drawing primitives, and input events — on top of a raw SDL3 FFI binding (no
third-party bindings package).

This is the foundation layer for a Nim GUI / game stack: higher-level packages
(widgets, layout, game views) import **only `gfx`** and never touch SDL.

## Backends

| Backend | Selected by | Status |
|---|---|---|
| SDL3 renderer | (default) | ✅ implemented |
| Cairo (software, AA vector + text) | `-d:useCairo` | ✅ implemented |

The public API is identical regardless of backend; coordinates are window
pixels.

## API

```nim
# types
type Color            # {r, g, b, a: uint8}
type Window; Renderer # opaque
type Key              # keyNone, keyBackspace, keyTab, keyEnter, keyEscape,
                      # keySpace, keyDelete, keyLeft/Right/Up/Down, keyHome/keyEnd,
                      # keyA..keyZ, key0..key9
type Button           # btnNone, btnLeft, btnMiddle, btnRight
type EventKind        # evNone, evQuit, evKeyDown, evKeyUp, evMouseDown,
                      # evMouseUp, evMouseMotion, evTextInput
type Event            # { kind, key, button, mouseX, mouseY, text }

# colors
proc rgb(r, g, b: uint8, a: uint8 = 255): Color
proc black(a: uint8 = 255): Color
proc white(a: uint8 = 255): Color
proc gray(v: uint8, a: uint8 = 255): Color

# lifecycle
proc openWindow(title: string, w, h: int): (Window, Renderer)
proc close(w: Window, r: Renderer)
proc shutdown()

# drawing
proc clear(r: Renderer, c: Color)
proc fillRect(r: Renderer, x, y, w, h: float, c: Color)
proc drawLine(r: Renderer, x1, y1, x2, y2: float, c: Color)
proc drawCircle(r: Renderer, cx, cy, radius: float, c: Color)
proc drawCircleOutline(r: Renderer, cx, cy, radius: float, c: Color)
proc roundedRect(r: Renderer, x, y, w, h, radius: float, c: Color)
proc present(r: Renderer)

# time + input
proc ticks(): int
proc pollEvent(): Option[Event]   # returns the next meaningful event, or none
```

## Build & run

```sh
# requires SDL3 (headers + lib) installed; Nim >= 2.0
nim c -r examples/hello.nim

# or the Cairo backend (requires libcairo):
nim c -r -d:useCairo examples/hello.nim
```

A window opens, draws a few primitives, and closes on `Esc` or the window ✕.

## Layout

```
src/
  gfx.nim        # public facade (types + backend selection)
  gfx_sdl.nim    # SDL3 renderer backend (default)
  gfx_cairo.nim  # Cairo software backend (-d:useCairo)
  sdl3.nim       # raw SDL3 FFI subset + shared window/input helpers
  sdl_events.nim # shared SDL -> gfx event translation
  cairo.nim      # raw Cairo FFI subset
examples/
  hello.nim      # smoke test
```

## License

[MIT](LICENSE). See [NOTICE.md](NOTICE.md) for third-party library licenses.
