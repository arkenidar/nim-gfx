#!/usr/bin/env sh
# Build all four backends of the nim-gfx smoke test into bin/.
# Works on Linux, Termux, and Windows (MSYS2 MinGW64) — just needs `nim`
# and the matching native libs.
set -e
cd "$(dirname "$0")/.."
mkdir -p bin
nim c --hints:off -d:useSdl3             -o:bin/hello_sdl3        examples/hello.nim
nim c --hints:off -d:useSdl2             -o:bin/hello_sdl2        examples/hello.nim
nim c --hints:off -d:useSdl3 -d:useCairo -o:bin/hello_cairo_sdl3 examples/hello.nim
nim c --hints:off -d:useSdl2 -d:useCairo -o:bin/hello_cairo_sdl2 examples/hello.nim
echo "Built into bin/:"
ls -la bin/
