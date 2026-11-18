#!/usr/bin/env sh
# Cross-compile all four backends to Windows .exe (then test them under Wine).
set -e
cd "$(dirname "$0")/.."

command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1 || {
  echo "error: x86_64-w64-mingw32-gcc not found (apt install gcc-mingw-w64-x86-64)" >&2
  exit 1
}

# Windows SDL2/SDL3/Cairo libs (override if your MSYS2 lives elsewhere).
: "${MSYS2_MINGW_LIB:=/mnt/windows/msys64/mingw64/lib}"
if [ ! -d "$MSYS2_MINGW_LIB" ]; then
  echo "error: $MSYS2_MINGW_LIB not found; set MSYS2_MINGW_LIB to your MSYS2 mingw64/lib dir" >&2
  exit 1
fi

# Stage ONLY the needed libs into a neutral dir, so the linker won't pick up
# MSYS2's mingw runtime (which ABI-clashes with the host cross-toolchain).
WINLIB="$(mktemp -d)"
trap 'rm -rf "$WINLIB"' EXIT
for lib in libSDL2.dll.a libSDL3.a libcairo.dll.a; do
  cp "$MSYS2_MINGW_LIB/$lib" "$WINLIB/" || {
    echo "error: missing $MSYS2_MINGW_LIB/$lib" >&2
    exit 1
  }
done

CC="--os:windows --cpu:amd64 --cc:gcc --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc --passL:-L$WINLIB"
mkdir -p bin
nim c --hints:off $CC -d:useSdl3             -o:bin/hello_sdl3.exe        examples/hello.nim
nim c --hints:off $CC -d:useSdl2             -o:bin/hello_sdl2.exe        examples/hello.nim
nim c --hints:off $CC -d:useSdl3 -d:useCairo -o:bin/hello_cairo_sdl3.exe examples/hello.nim
nim c --hints:off $CC -d:useSdl2 -d:useCairo -o:bin/hello_cairo_sdl2.exe examples/hello.nim

echo "Done. Run under Wine with:"
echo "  WINEPATH=$MSYS2_MINGW_LIB/../bin wine bin/<name>.exe"
