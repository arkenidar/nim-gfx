# nim-gfx

A small, backend-agnostic graphics facade for Nim: a window + renderer, colors,
drawing primitives, and input events — on top of raw SDL2/SDL3/Cairo FFI
bindings (no third-party bindings package).

This is the foundation layer for a Nim GUI / game stack: higher-level layers
(layout, views) import **only `gfx`** and never touch SDL.

## Roadmap

`nim-gfx` is a graphics lib plus (in the `ui/` subfolder) a minimal UI kit.
Dependencies are one-way: `gfx.*` never knows about `ui.*`.

```
src/
  gfx...             # graphics + input (draw, pollEvent, clip, ...)
  ui/
    events.nim        # shape hit-testing (hitRect / hitCircle / hitRoundedRect)
    layout.nim        # (deferred — no design yet)
    view.nim          # (deferred)
    patterns.nim      # (deferred) button / scrollable pane / text input recipes
```

| Area | Status |
|---|---|
| 4 backends (SDL2/SDL3/Cairo x2), explicit selection | done |
| Input: key / mouse / text / wheel / touch(finger) / resize + clip rect | done |
| Text: `drawText` / `drawTextWrapped` / `textSize` (via Pango) | done |
| Fixed logical canvas + letterbox (rememe's model; draw + input consistent) | done |
| Window controls: `maximize` / `setFullscreen` / `windowSize` | done |
| `ui/events`: shape hit-testing | done |
| Clipboard (copy/paste) | next |
| `ui/layout` / `ui/view` / `ui/patterns` | deferred (no design yet) |

No widget framework: screens draw + hit-test inline; `ui/patterns.nim` holds the
three most useful recipes.

## Backends

| Backend | Selected by | Status |
|---|---|---|
| SDL3 renderer | `-d:useSdl3` | ✅ |
| SDL2 renderer | `-d:useSdl2` | ✅ |
| Cairo (anti-aliased) on SDL3 | `-d:useSdl3 -d:useCairo` | ✅ |
| Cairo (anti-aliased) on SDL2 | `-d:useSdl2 -d:useCairo` | ✅ |

There is **no default backend** — a build must pass one of the flags above.

The public API is identical regardless of backend. Coordinates are logical
after `setLogicalSize` — a fixed canvas, letterboxed into the window (rememe's
model: one canvas, one mapping, no modes). Without it they are window pixels.

## API

```nim
# types
type Color            # {r, g, b, a: uint8}
type Window; Renderer # opaque
type Key              # keyNone, keyBackspace, keyTab, keyEnter, keyEscape,
                      # keySpace, keyDelete, keyLeft/Right/Up/Down, keyHome/keyEnd,
                      # keyA..keyZ, key0..key9
type Button           # btnNone, btnLeft, btnMiddle, btnRight
type EventKind        # evNone, evQuit, evKeyDown/Up, evMouseDown/Up/Motion/Wheel,
                      # evTextInput, evFingerDown/Up/Motion, evResize
type Event            # { kind, key, button, mouseX/Y, wheelX/Y, text,
                      #   fingerId, fingerX/Y/Dx/Dy/pressure, resizeW/H }

# colors
proc rgb(r, g, b: uint8, a: uint8 = 255): Color
proc black/white/gray(a: uint8 = 255): Color

# lifecycle
proc openWindow(title: string, w, h: int): (Window, Renderer)
proc close(w: Window, r: Renderer)
proc shutdown()

# window controls
proc windowSize(w: Window): (int, int)
proc maximize(w: Window)
proc setFullscreen(w: Window, fs: bool)

# logical canvas (fixed, letterboxed into the window)
proc setLogicalSize(r: Renderer, w, h: float)

# drawing
proc clear, fillRect, drawLine, drawCircle, drawCircleOutline, roundedRect
proc setClipRect(r: Renderer, x, y, w, h: float)
proc resetClip(r: Renderer)
proc present(r: Renderer)

# text (Cairo backends only)
proc drawText(r, x, y, text, c, size = 12.0, family = "sans")
proc drawTextWrapped(r, x, y, width, text, c, size, family)
proc textSize(r, text, size, family): (int, int)

# time + input
proc ticks(): int
proc pollEvent(): Option[Event]
```

## Build & run

```sh
# requires SDL3 and/or SDL2 (+ libcairo for the Cairo backends); Nim >= 2.0
nim c -r -d:useSdl3 examples/hello.nim                # SDL3 renderer
nim c -r -d:useSdl2 examples/hello.nim                # SDL2 renderer
nim c -r -d:useSdl3 -d:useCairo examples/hello.nim    # Cairo on SDL3
nim c -r -d:useSdl2 -d:useCairo examples/hello.nim    # Cairo on SDL2
```

A window opens, draws a few primitives, and closes on `Esc` or the window ✕.

## Build all backends (scripts)

```sh
./scripts/build-all.sh       # 4 native binaries -> bin/
./scripts/build-all-win.sh   # 4 Windows .exe -> bin/ (cross-compile for Wine)
```

`build-all-win.sh` cross-compiles from Linux; it needs `gcc-mingw-w64-x86-64`
and the MSYS2 import libs (override `MSYS2_MINGW_LIB` if your MSYS2 is elsewhere).

On Termux: `./scripts/termux-setup.sh`, then `./scripts/build-all.sh`.

## Windows (MSYS2 MinGW64)

On Windows, the easiest native build is via MSYS2's **MinGW64** environment.
Use the **`MSYS2 MinGW64`** shell — *not* the plain `MSYS2` shell, whose binaries
depend on `msys-2.0.dll`:

```sh
# in the MSYS2 MinGW64 shell
pacman -S mingw-w64-x86_64-SDL2           # SDL2 backend
pacman -S mingw-w64-x86_64-SDL3           # SDL3 backend (if packaged; else use the
                                          # SDL3 MinGW dev tarball from libsdl.org)
pacman -S mingw-w64-x86_64-cairo          # Cairo backends

nim c -r -d:useSdl3 examples/hello.nim             # SDL3 backend
nim c -r -d:useSdl2 examples/hello.nim             # SDL2 backend
nim c -r -d:useSdl3 -d:useCairo examples/hello.nim # Cairo on SDL3
nim c -r -d:useSdl2 -d:useCairo examples/hello.nim # Cairo on SDL2
```

Inside the MinGW64 shell, `-lcairo` and `-lSDL3` resolve from `/mingw64/lib`
automatically, and running the built `.exe` from that same shell finds the
Cairo DLLs because `/mingw64/bin` is already on `PATH`. (The SDL-backend `.exe`
is self-contained — static SDL3 — and runs from anywhere.)

For local dev you can skip copying DLLs and just keep the MinGW64 `bin` on
`PATH` (it is, inside the shell); add `C:\msys64\mingw64\bin` to the system
`PATH` to double-click from Explorer. Under Wine, use
`WINEPATH=/path/to/msys64/mingw64/bin`. To ship a *standalone* `.exe`, copy the
DLLs beside it:

```sh
ldd examples/hello.exe
# typical: libcairo-2.dll, libpixman-1-0.dll, libpng16-16.dll, zlib1.dll,
#          libfreetype-6.dll, libfontconfig-1.dll, libexpat-1.dll, ...
```

### Cross-compiling from Linux (to test under Wine)

With `gcc-mingw-w64-x86-64` installed you can build Windows `.exe` files and run
them under Wine. Put only the SDL2/Cairo *import* libs in a neutral `-L` dir so
they don't clash with the host mingw runtime:

```sh
mkdir -p /tmp/winlib && cp <msys64>/mingw64/lib/libSDL2.dll.a <msys64>/mingw64/lib/libcairo.dll.a /tmp/winlib/
nim c --os:windows --cpu:amd64 --cc:gcc \
     --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc \
     --passL:-L/tmp/winlib -d:useSdl2 -o:hello.exe examples/hello.nim
WINEPATH=<msys64>/mingw64/bin wine hello.exe
```

## Termux (Android)

`nim`, `sdl2`, `sdl3` and `libcairo` are packaged (run under Termux:X11 with
`DISPLAY=:0`):

```sh
./scripts/termux-setup.sh        # nim, sdl2, sdl3, libcairo, pango, ttf-dejavu
git clone https://github.com/arkenidar/nim-gfx && cd nim-gfx
nim c -r -d:useSdl2 -d:useCairo examples/textdemo.nim
```

To make the window fill the whole Android screen, set Termux:X11's display
resolution to match the device and enable fullscreen/immersive in its settings —
that is an Android-app setting, not a nim-gfx code setting.

## Layout

```
src/
  gfx.nim            # public facade (types + backend selection)
  gfx_sdl3.nim       # SDL3 renderer backend
  gfx_sdl2.nim       # SDL2 renderer backend
  gfx_cairo_sdl3.nim # Cairo on SDL3
  gfx_cairo_sdl2.nim # Cairo on SDL2
  sdl3.nim           # raw SDL3 FFI + shared window/input helpers
  sdl2.nim           # raw SDL2 FFI + shared window/input helpers
  sdl_events.nim     # SDL3 -> gfx event translation
  sdl2_events.nim    # SDL2 -> gfx event translation
  cairo.nim          # raw Cairo FFI subset
examples/
  hello.nim          # smoke test
```

## License

[MIT](LICENSE). See [NOTICE.md](NOTICE.md) for third-party library licenses.
