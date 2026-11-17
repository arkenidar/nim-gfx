# Third-party notices

`nim-gfx` links against the following native libraries.

## SDL3

Simple DirectMedia Layer 3 — **zlib License**.
https://github.com/libsdl-org/SDL/blob/main/LICENSE.txt

## Cairo (optional backend, selected with `-d:useCairo`)

Cairo 2D graphics library — dual licensed under **LGPL-2.1 OR MPL-1.1**.
Prefer dynamic linking (the shared library) to keep this project's MIT terms
clean; static linking carries LGPL relinking obligations.
https://gitlab.freedesktop.org/cairo/cairo

## FreeType (optional, Cairo text path)

The FreeType Project — **FTL** (FreeType License).
https://freetype.org

## fontconfig (optional, Cairo text path)

fontconfig — **MIT-style** license.
https://gitlab.freedesktop.org/fontconfig/fontconfig
