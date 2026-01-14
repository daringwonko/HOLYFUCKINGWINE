#!/bin/bash
##############################################################################
# SketchUp 2026 Wine Debug Script
# Runs installer with proper exports and WoW64 diagnostic logging
##############################################################################

set -e

# CRITICAL: Export all environment variables so wine subprocess inherits them
export WINEPREFIX="$HOME/.sketchup2026"
export WINEARCH=win64
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Debug logging: +wow traces WoW64 API, +module traces DLL loading
export WINEDEBUG=+wow,+err,+loaddll

# Installer path
INSTALLER="$HOME/SketchUp-2026-1-189-46.exe"

echo "=== SketchUp 2026 Wine Debug Run ==="
echo "Date: $(date)"
echo ""
echo "Environment Configuration:"
echo "  WINEPREFIX: $WINEPREFIX"
echo "  WINEARCH: $WINEARCH"
echo "  WINEDEBUG: $WINEDEBUG"
echo "  GPU Offload: NV_PRIME_RENDER_OFFLOAD=1"
echo ""

# Validate WINEPREFIX exists
if [ ! -d "$WINEPREFIX" ]; then
    echo "ERROR: Wine prefix does not exist at: $WINEPREFIX"
    echo "Please run the setup scripts first."
    exit 1
fi
echo "✓ Wine prefix exists: $WINEPREFIX"

# Validate installer exists
if [ ! -f "$INSTALLER" ]; then
    echo "ERROR: Installer not found at: $INSTALLER"
    exit 1
fi
echo "✓ Installer found: $INSTALLER"
echo "  File type: $(file -b "$INSTALLER")"
echo ""

# Show Wine architecture info
echo "Wine Configuration:"
echo "  Wine version: $(wine --version)"
echo "  Prefix arch: $(grep '#arch=' "$WINEPREFIX/system.reg" 2>/dev/null | head -1 || echo 'unknown')"
echo ""

# Check if both Program Files exist (WoW64 indicator)
echo "WoW64 Check:"
if [ -d "$WINEPREFIX/drive_c/Program Files" ] && [ -d "$WINEPREFIX/drive_c/Program Files (x86)" ]; then
    echo "  ✓ Both Program Files directories exist (WoW64 enabled)"
else
    echo "  ✗ WoW64 may not be properly configured"
fi
echo ""

echo "Starting installer with WoW64 debug logging..."
echo "Output will be saved to: wine-wow64-debug.log"
echo "=================================================="
echo ""

# Run wine with full WoW64 tracing
wine "$INSTALLER" > wine-wow64-debug.log 2>&1

echo ""
echo "=== Debug run complete ==="
echo "Review: wine-wow64-debug.log"
echo ""
echo "To search for WoW64 issues:"
echo "  grep -i 'wow64\|iswow64' wine-wow64-debug.log"
