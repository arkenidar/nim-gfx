# nim-gfx

A small graphics facade for Nim: a window + renderer, colors, drawing
primitives, and input events — on top of raw SDL2/Cairo/Pango FFI bindings (no
third-party bindings package).

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
| Single backend (SDL2 + Cairo + Pango), no flags | done |
| Input: key / mouse / text / wheel / touch(finger) / resize + clip rect | done |
| Text: `drawText` / `drawTextWrapped` / `textSize` (via Pango) | done |
| Fixed logical canvas + letterbox (rememe's model; draw + input consistent) | done |
| Window controls: `maximize` / `setFullscreen` / `windowSize` | done |
| `ui/events`: shape hit-testing | done |
| Clipboard (copy/paste) | next |
| `ui/layout` / `ui/view` / `ui/patterns` | deferred (no design yet) |

No widget framework: screens draw + hit-test inline; `ui/patterns.nim` holds the
three most useful recipes.

## Backend

One backend, no compile-time flags: **SDL2** (window + input) + **Cairo**
(drawing) + **Pango** (text).

Coordinates are logical after `setLogicalSize` — a fixed canvas, letterboxed
into the window (rememe's model: one canvas, one mapping, no modes). Without it
they are window pixels.

For a responsive layout, re-call `setLogicalSize` from the `evResize` handler
with a canvas matching the new window orientation (e.g. portrait 480x640 vs
landscape 640x480) and re-layout your content — see the examples.

Text renders through Pango pinned to its **FreeType/fontconfig** backend — not
Windows' win32/DirectWrite backend, which scrambles glyphs when rasterizing onto
a Cairo *image* surface (our blit path). This also keeps glyphs pixel-identical
across Linux, Windows, and Wine.

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

# text (Pango)
proc drawText(r, x, y, text, c, size = 12.0, family = "sans")
proc drawTextWrapped(r, x, y, width, text, c, size, family)
proc textSize(r, text, size, family): (int, int)

# time + input
proc ticks(): int
proc pollEvent(): Option[Event]
```

## Build & run

```sh
# requires SDL2 + libcairo + Pango; Nim >= 2.0
nim c -r examples/hello.nim
```

A window opens, draws a few primitives, and closes on `Esc` or the window ✕.

## Build all examples (scripts)

```sh
./scripts/build-all.sh       # every examples/*.nim -> bin/
./scripts/build-all-win.sh   # every examples/*.nim -> bin/*.exe (cross-compile)
```

`build-all.sh` builds every `.nim` in `examples/` automatically.
`build-all-win.sh` cross-compiles from Linux (needs `gcc-mingw-w64-x86-64` and
the MSYS2 import libs; override `MSYS2_MINGW_LIB` if your MSYS2 is elsewhere)
and, if `wine` is installed, smoke-tests each `.exe --smoke` (one frame, exit).
The Wine step also seeds one host font into Wine's prefix
(`~/.wine/drive_c/windows/Fonts`, which Wine ships empty) so the FreeType text
backend has a font to find; on real Windows this isn't needed.

On Termux: `./scripts/termux-setup.sh`, then `./scripts/build-all.sh`.

## Windows (MSYS2 MinGW64)

On Windows, the easiest native build is via MSYS2's **MinGW64** environment.
Use the **`MSYS2 MinGW64`** shell — *not* the plain `MSYS2` shell, whose binaries
depend on `msys-2.0.dll`:

```sh
# in the MSYS2 MinGW64 shell
pacman -S mingw-w64-x86_64-SDL2           # SDL2
pacman -S mingw-w64-x86_64-cairo          # Cairo
pacman -S mingw-w64-x86_64-pango          # Pango (text)

nim c -r examples/hello.nim
```

Inside the MinGW64 shell, `-lcairo` and `-lSDL2` resolve from `/mingw64/lib`
automatically, and running the built `.exe` from that same shell finds the
Cairo DLLs because `/mingw64/bin` is already on `PATH`.

For local dev you can skip copying DLLs and just keep the MinGW64 `bin` on
`PATH` (it is, inside the shell); add `C:\msys64\mingw64\bin` to the system
`PATH` to double-click from Explorer. Under Wine, use
`WINEPATH=/path/to/msys64/mingw64/bin`. To ship a *standalone* `.exe`, copy the
DLLs beside it:

```sh
ldd examples/hello.exe
# typical: libcairo-2.dll, libpixman-1-0.dll, libpng16-16.dll, zlib1.dll,
#          libpango-1.0-0.dll, libpangocairo-1.0-0.dll, libfreetype-6.dll,
#          libfontconfig-1.dll, libexpat-1.dll, ...
```

### Cross-compiling from Linux (to test under Wine)

With `gcc-mingw-w64-x86-64` installed you can build Windows `.exe` files and run
them under Wine. Put the needed *import* libs in a neutral `-L` dir so they
don't clash with the host mingw runtime (add Pango's for `textdemo`):

```sh
mkdir -p /tmp/winlib && cp <msys64>/mingw64/lib/libSDL2.dll.a <msys64>/mingw64/lib/libcairo.dll.a /tmp/winlib/
nim c --os:windows --cpu:amd64 --cc:gcc \
     --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc \
     --passL:-L/tmp/winlib -o:hello.exe examples/hello.nim
WINEPATH=<msys64>/mingw64/bin wine hello.exe --smoke
```

## Termux (Android)

`nim`, `sdl2` and `libcairo` are packaged (run under Termux:X11 with
`DISPLAY=:0`):

```sh
./scripts/termux-setup.sh        # nim, sdl2, libcairo, pango, ttf-dejavu, openbox
git clone https://github.com/arkenidar/nim-gfx && cd nim-gfx
nim c -r examples/textdemo.nim
```

On Termux the window auto-sizes to the display and centers itself (Termux:X11
has no window manager), and on screen rotation it re-sizes + re-centers so the
app keeps filling the screen; the fixed logical canvas re-letterboxes itself.

For the fullscreen toggle (`F`) and WM-managed rotation, install a lightweight
window manager (`pkg install openbox`) and start it before your app —
`DISPLAY=:0 openbox &` (or set it as Termux:X11's startup command). Without a
WM, fullscreen (`SDL_WINDOW_FULLSCREEN_DESKTOP`) has no effect.

## Layout

```
src/
  gfx.nim            # public facade (single backend)
  gfx_cairo_sdl2.nim # Cairo software backend on the SDL2 shell
  sdl2.nim           # raw SDL2 FFI + window/input helpers
  sdl2_events.nim    # SDL2 -> gfx event translation
  cairo.nim          # raw Cairo FFI subset
  pango.nim          # raw Pango FFI subset
examples/
  hello.nim          # smoke test
  textdemo.nim       # text + picking demo
```

## License

[MIT](LICENSE). See [NOTICE.md](NOTICE.md) for third-party library licenses.
