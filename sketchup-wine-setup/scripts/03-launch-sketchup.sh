#!/bin/bash
##############################################################################
# SketchUp 2026 Launch Script with NVIDIA GPU Offloading
# For: Fedora 42 Workstation with NVIDIA GTX 1050 Ti hybrid graphics
# This script handles all environment setup for optimal performance
##############################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WINE_PREFIX="${HOME}/.sketchup2026"
WINEARCH=win64
WINEDEBUG=-all

# GPU OFFLOADING FOR HYBRID GRAPHICS (Intel iGPU + NVIDIA GTX 1050 Ti)
# These variables force Wine to use the NVIDIA GPU instead of Intel HD 630
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Additional NVIDIA optimizations for better stability
export __NV_PRIME_RENDER_OFFLOAD_PROC_PID=1
export VK_LOADER_DEBUG=error
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

# Audio/latency optimization
export PULSE_LATENCY_MSEC=0

# Export variables
export WINEPREFIX="$WINE_PREFIX"
export WINEARCH
export WINEDEBUG

# Search paths for SketchUp installation
SKETCHUP_SEARCH_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/SketchUp/SketchUp 2026/SketchUp.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/SketchUp/SketchUp 2026/SketchUp.exe"
    "$WINE_PREFIX/drive_c/Program Files/SketchUp/SketchUp 2026/bin/SketchUp.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/SketchUp/SketchUp 2026/bin/SketchUp.exe"
)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SketchUp 2026 Launch Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Wine prefix exists
if [ ! -d "$WINE_PREFIX" ]; then
    echo -e "${RED}✗ Wine prefix not found at: $WINE_PREFIX${NC}"
    echo "Run ./scripts/00-master-setup.sh first"
    exit 1
fi

# Find SketchUp installation
SKETCHUP_EXE=""
for path in "${SKETCHUP_SEARCH_PATHS[@]}"; do
    if [ -f "$path" ]; then
        SKETCHUP_EXE="$path"
        break
    fi
done

if [ -z "$SKETCHUP_EXE" ]; then
    echo -e "${RED}✗ SketchUp 2026 not found in Wine prefix!${NC}"
    echo "Searched paths:"
    for path in "${SKETCHUP_SEARCH_PATHS[@]}"; do
        echo "  - $path"
    done
    echo ""
    echo -e "${YELLOW}Please run ./scripts/04-install-sketchup.sh first${NC}"
    exit 1
fi

# Display startup information
echo "=== Launching SketchUp 2026 ==="
echo "Wine Prefix: $WINEPREFIX"
echo "Wine Arch: $WINEARCH"
echo "SketchUp Path: $SKETCHUP_EXE"
echo ""
echo "GPU Offloading Configuration:"
echo "  __NV_PRIME_RENDER_OFFLOAD=1"
echo "  __GLX_VENDOR_LIBRARY_NAME=nvidia"
echo "  Target GPU: NVIDIA GTX 1050 Ti"
echo "  (Intel HD 630 will be bypassed)"
echo ""
echo "Starting SketchUp..."
echo ""

# Launch SketchUp with all environment variables set
wine "$SKETCHUP_EXE" "$@"
