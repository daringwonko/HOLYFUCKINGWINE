#!/bin/bash
set -e
WINEPREFIX=\"$HOME/.sketchup2026\" \
__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
WINEDEBUG=+err,+loaddll \
wine \"$HOME/SketchUp-2026-1-189-46.exe\" > wine-debug.log 2>&1