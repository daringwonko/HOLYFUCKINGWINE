#!/bin/bash
##############################################################################
# SketchUp 2026 Installer Script
# Installs SketchUp 2026 into the configured Wine prefix
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if installer path is provided as command line argument
if [ $# -ge 1 ]; then
    if [ -f "$1" ]; then
        FOUND_INSTALLER="$1"
        echo -e "${BLUE}Using installer from command line argument:${NC}"
        echo "  Path: $FOUND_INSTALLER"
        echo ""
    else
        echo -e "${RED}✗ File not found: $1${NC}"
        exit 1
    fi
fi

# Configuration
WINE_PREFIX="${HOME}/.sketchup2026"
INSTALLER_SEARCH_PATHS=(
    "${HOME}/SketchUp 2026/SketchUp2026Installer.exe"
    "${HOME}/SketchUp 2026/SketchUpInstaller.exe"
    "${HOME}/SketchUp 2026/SketchUp.exe"
    "${HOME}/Downloads/SketchUp*2026*.exe"
    "/tmp/SketchUp*2026*.exe"
    "${HOME}/SketchUp*2026*.exe"
)

# GPU Offloading Variables
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export WINEPREFIX="$WINE_PREFIX"
export WINEARCH=win64
export WINEDEBUG=-all

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SketchUp 2026 Wine Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if WINEPREFIX exists
if [ ! -d "$WINE_PREFIX" ]; then
    echo -e "${RED}✗ Wine prefix not found at: $WINE_PREFIX${NC}"
    echo "Run ./scripts/00-master-setup.sh first"
    exit 1
fi

echo -e "${GREEN}✓ Wine prefix found at: $WINE_PREFIX${NC}"
echo ""

# If installer wasn't provided as command-line argument, find it automatically
if [ -z "$FOUND_INSTALLER" ]; then
    # Find SketchUp installer
    for path in "${INSTALLER_SEARCH_PATHS[@]}"; do
        if [ -f "$path" ]; then
            FOUND_INSTALLER="$path"
            break
        fi
        # Handle wildcard paths
        if ls $path 2>/dev/null | head -1 | grep -q . 2>/dev/null; then
            FOUND_INSTALLER=$(ls $path 2>/dev/null | head -1)
            break
        fi
    done

    if [ -z "$FOUND_INSTALLER" ]; then
        echo -e "${YELLOW}SketchUp 2026 installer not found!${NC}"
        echo ""
        echo "Searched locations:"
        for path in "${INSTALLER_SEARCH_PATHS[@]}"; do
            echo "  - $path"
        done
        echo ""
        echo "Please provide the path to the installer:"
        read -p "Installer path: " FOUND_INSTALLER
        
        if [ ! -f "$FOUND_INSTALLER" ]; then
            echo -e "${RED}✗ File not found: $FOUND_INSTALLER${NC}"
            exit 1
        fi
    fi
fi

INSTALLER_SIZE=$(du -h "$FOUND_INSTALLER" | cut -f1)
echo -e "${BLUE}Found SketchUp installer:${NC}"
echo "  Path: $FOUND_INSTALLER"
echo "  Size: $INSTALLER_SIZE"
echo ""

# Verify Wine setup
echo -e "${BLUE}Verifying Wine configuration...${NC}"
echo "  Wine: $(wine --version)"
echo "  Architecture: $(WINEPREFIX="$WINE_PREFIX" wine uname -m 2>/dev/null || echo 'x86_64')"
echo ""

# Show system info
echo -e "${BLUE}System Information:${NC}"
if command -v nvidia-smi &>/dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "NVIDIA GPU")
    echo "  GPU: $GPU_NAME"
    echo "  GPU Offloading: ENABLED"
else
    echo "  GPU: NVIDIA (environment variables set)"
fi
echo ""

# Pre-installation checks
echo -e "${BLUE}Pre-Installation Checks:${NC}"

# Check for required components
echo -n "  Checking .NET 4.8... "
if WINEPREFIX="$WINE_PREFIX" wine reg query "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full" 2>/dev/null | grep -q "Release"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}? (may install automatically)${NC}"
fi

echo -n "  Checking WebView2... "
if WINEPREFIX="$WINE_PREFIX" wine reg query "HKEY_LOCAL_MACHINE\\Software\\WOW6432Node\\Microsoft\\EdgeUpdate\\Clients" 2>/dev/null | grep -q "pv"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}? (may install automatically)${NC}"
fi

echo ""
echo -e "${YELLOW}Ready to install SketchUp 2026${NC}"
read -p "Continue with installation? (y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 0
fi

echo ""
echo -e "${BLUE}Starting SketchUp installation...${NC}"
echo "(This will open the SketchUp installer window)"
echo ""

# Run installer with GPU offloading
WINEPREFIX="$WINE_PREFIX" wine "$FOUND_INSTALLER"

# Check if installation succeeded
echo ""
if [ -f "$WINE_PREFIX/drive_c/Program Files/SketchUp/SketchUp 2026/SketchUp.exe" ] || \
   [ -f "$WINE_PREFIX/drive_c/Program Files (x86)/SketchUp/SketchUp 2026/SketchUp.exe" ]; then
    echo -e "${GREEN}✓ SketchUp 2026 installed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Launch SketchUp: ./scripts/03-launch-sketchup.sh"
    echo "  2. Log in with your Trimble Identity (WebView2 login screen)"
    echo "  3. Configure GPU settings if needed"
else
    echo -e "${YELLOW}! Installation status unclear${NC}"
    echo "The installer may still be running. Check if SketchUp is installed:"
    echo "  ls -la \"$WINE_PREFIX/drive_c/Program Files/SketchUp/\""
fi

echo ""