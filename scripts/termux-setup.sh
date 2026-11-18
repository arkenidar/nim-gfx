#!/usr/bin/env sh
# Install nim-gfx's Termux dependencies (idempotent).
set -e
pkg update
pkg upgrade -y
pkg install -y nim x11-repo          # nim pulls clang + git automatically
pkg install -y sdl2 sdl3 libcairo pango ttf-dejavu
echo "Deps installed. Next:"
echo "  git clone https://github.com/arkenidar/nim-gfx && cd nim-gfx"
echo "  ./scripts/build-all.sh"
echo "  nim c -r -d:useSdl2 examples/textdemo.nim"
