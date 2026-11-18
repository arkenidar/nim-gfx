#!/usr/bin/env sh
# Cross-compile all examples to Windows .exe, then smoke-test under Wine.
set -e
cd "$(dirname "$0")/.."

command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1 || {
  echo "error: x86_64-w64-mingw32-gcc not found (apt install gcc-mingw-w64-x86-64)" >&2
  exit 1
}

# Windows SDL2/Cairo/Pango libs (override if your MSYS2 lives elsewhere).
: "${MSYS2_MINGW_LIB:=/mnt/windows/msys64/mingw64/lib}"
if [ ! -d "$MSYS2_MINGW_LIB" ]; then
  echo "error: $MSYS2_MINGW_LIB not found; set MSYS2_MINGW_LIB to your MSYS2 mingw64/lib dir" >&2
  exit 1
fi

# Stage ONLY the needed libs into a neutral dir, so the linker won't pick up
# MSYS2's mingw runtime (which ABI-clashes with the host cross-toolchain).
WINLIB="$(mktemp -d)"
trap 'rm -rf "$WINLIB"' EXIT
for lib in libSDL2.dll.a libcairo.dll.a libpangocairo-1.0.dll.a \
           libpango-1.0.dll.a libgobject-2.0.dll.a libglib-2.0.dll.a; do
  cp "$MSYS2_MINGW_LIB/$lib" "$WINLIB/" || {
    echo "error: missing $MSYS2_MINGW_LIB/$lib" >&2
    echo "  in the MSYS2 MinGW64 shell, install it with:" >&2
    echo "    pacman -S mingw-w64-x86_64-SDL2 mingw-w64-x86_64-cairo mingw-w64-x86_64-pango" >&2
    exit 1
  }
done

CC="--os:windows --cpu:amd64 --cc:gcc --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --passL:-L$WINLIB"
mkdir -p bin
for ex in examples/*.nim; do
  name=$(basename "$ex" .nim)
  nim c --hints:off $CC -o:"bin/${name}.exe" "$ex"
done

if command -v wine >/dev/null 2>&1; then
  # Wine's prefix has no fonts (and MSYS2 ships none), so seed one host font
  # into C:\Windows\Fonts for the FreeType text backend to find.
  WIN_FONTS="$HOME/.wine/drive_c/windows/Fonts"
  if [ -d "$WIN_FONTS" ] && [ -z "$(ls -A "$WIN_FONTS" 2>/dev/null)" ]; then
    for f in /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
             /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf \
             /usr/share/fonts/truetype/noto/NotoSans-Regular.ttf; do
      if [ -f "$f" ]; then cp "$f" "$WIN_FONTS/"; echo "seeded Wine font: $f"; break; fi
    done
  fi
  echo "Smoke-testing under Wine (one frame each):"
  for ex in bin/*.exe; do
    echo "  wine $(basename "$ex") --smoke"
    WINEDEBUG=-all WINEPATH="$MSYS2_MINGW_LIB/../bin" wine "$ex" --smoke
  done
else
  echo "wine not found — skipping runtime verification."
fi
