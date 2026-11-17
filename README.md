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

## Windows (MSYS2 MinGW64)

On Windows, the easiest native build is via MSYS2's **MinGW64** environment.
Use the **`MSYS2 MinGW64`** shell — *not* the plain `MSYS2` shell, whose binaries
depend on `msys-2.0.dll`:

```sh
# in the MSYS2 MinGW64 shell
pacman -S mingw-w64-x86_64-cairo          # libcairo (Cairo backend)
pacman -S mingw-w64-x86_64-SDL3           # SDL3 (if packaged; else use the
                                          # SDL3 MinGW dev tarball from libsdl.org)

nim c -r examples/hello.nim                # default SDL backend
nim c -r -d:useCairo examples/hello.nim    # Cairo backend
```

Inside the MinGW64 shell, `-lcairo` and `-lSDL3` resolve from `/mingw64/lib`
automatically. To ship a standalone `.exe`, list its DLL dependencies and copy
them beside it:

```sh
ldd examples/hello.exe
# typical: libcairo-2.dll, libpixman-1-0.dll, libpng16-16.dll, zlib1.dll,
#          libfreetype-6.dll, libfontconfig-1.dll, libexpat-1.dll, ...
```

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
