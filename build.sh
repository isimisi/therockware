#!/bin/bash
# Build the single self-contained executable.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p build
clang++ -x objective-c++ -std=c++17 -fobjc-arc -O2 \
  -Wall -Wno-unused-parameter \
  -mmacosx-version-min=11.0 \
  mac.cpp -o build/therockware \
  -framework Cocoa \
  -framework QuartzCore \
  -framework AVFoundation \
  -framework ApplicationServices \
  -framework ImageIO

# Ad-hoc sign so macOS has a stable identity to hang the Accessibility
# permission on.
codesign --force --sign - build/therockware

echo "built build/therockware ($(du -h build/therockware | cut -f1))"
