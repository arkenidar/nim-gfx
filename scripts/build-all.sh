#!/usr/bin/env sh
# Build all examples into bin/ (single backend: SDL2 + Cairo + Pango).
# Works on Linux and Termux — just needs `nim` and the native libs.
set -e
cd "$(dirname "$0")/.."
mkdir -p bin
for ex in examples/*.nim; do
  name=$(basename "$ex" .nim)
  nim c --hints:off -o:"bin/$name" "$ex"
done
echo "Built into bin/:"
ls -la bin/
