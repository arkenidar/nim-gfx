# Third-party notices

`nim-gfx` links against the following native libraries.

## SDL2

Simple DirectMedia Layer 2 — **zlib License**.
https://github.com/libsdl-org/SDL/blob/SDL2/LICENSE.txt

## Cairo

Cairo 2D graphics library — dual licensed under **LGPL-2.1 OR MPL-1.1**.
Prefer dynamic linking (the shared library) to keep this project's MIT terms
clean; static linking carries LGPL relinking obligations.
https://gitlab.freedesktop.org/cairo/cairo

## Pango

Pango text layout library — **LGPL-2.1-or-later**.
Prefer dynamic linking (the shared library) to keep this project's MIT terms clean.
https://gitlab.gnome.org/GNOME/pango

## FreeType (transitive, via Cairo/Pango)

The FreeType Project — **FTL** (FreeType License).
https://freetype.org

## fontconfig (transitive, via Pango)

fontconfig — **MIT-style** license.
https://gitlab.freedesktop.org/fontconfig/fontconfig
