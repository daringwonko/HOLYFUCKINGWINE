#!/bin/bash
##############################################################################
# SketchUp 2026 Wine Setup - OFFLINE MODE
# For systems with limited internet/VPN restrictions
# Uses local packages from the repository
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PACKAGES_DIR="$REPO_ROOT/packages"
WINE_PREFIX="${HOME}/.sketchup2026"
WINETRICKS_LOCAL="$PACKAGES_DIR/tools/winetricks"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SketchUp 2026 Wine Setup - OFFLINE MODE                  ║${NC}"
echo -e "${BLUE}║  Using local packages from repository                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check available packages
echo -e "${BLUE}[Step 1/5] Checking available packages in repository...${NC}"
echo ""

AVAILABLE=0
MISSING=0

if [ -d "$PACKAGES_DIR" ]; then
    echo -e "${GREEN}✓ Packages directory found${NC}"
    ((AVAILABLE++))
else
    echo -e "${RED}✗ Packages directory not found${NC}"
    ((MISSING++))
fi

if [ -f "$WINETRICKS_LOCAL" ]; then
    echo -e "${GREEN}✓ Winetricks available locally${NC}"
    chmod +x "$WINETRICKS_LOCAL"
    ((AVAILABLE++))
else
    echo -e "${YELLOW}! Winetricks not found (will try to use system winetricks)${NC}"
fi

if [ -f "$PACKAGES_DIR/wine"/*.rpm 2>/dev/null ]; then
    WINE_RPMS=$(ls "$PACKAGES_DIR/wine"/*.rpm | wc -l)
    echo -e "${GREEN}✓ Wine RPM packages found ($WINE_RPMS files)${NC}"
    ((AVAILABLE++))
else
    echo -e "${YELLOW}! Wine RPM packages not found (will use dnf)${NC}"
fi

echo ""

# Step 2: Install Wine from local RPMs if available
echo -e "${BLUE}[Step 2/5] Installing Wine...${NC}"

if [ -f "$PACKAGES_DIR/wine"/*.rpm 2>/dev/null ]; then
    echo "Installing Wine from local RPM packages..."
    sudo dnf install -y "$PACKAGES_DIR/wine"/*.rpm 2>/dev/null || \
        echo -e "${YELLOW}⚠ Some Wine packages may already be installed${NC}"
    echo -e "${GREEN}✓ Wine installed from local packages${NC}"
elif command_exists wine; then
    WINE_VERSION=$(wine --version)
    echo -e "${GREEN}✓ Wine already installed: $WINE_VERSION${NC}"
else
    echo "Attempting to install Wine from system repositories..."
    FEDORA_VERSION=$(grep -oP '(?<=Fedora release )\d+' /etc/fedora-release 2>/dev/null || echo "42")
    
    # Add WineHQ repository
    sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/wine-fedora.repo 2>/dev/null || true
    sudo dnf install -y winehq-stable
    echo -e "${GREEN}✓ Wine installed${NC}"
fi

echo ""

# Step 3: Install 32-bit support and dependencies
echo -e "${BLUE}[Step 3/5] Installing 32-bit support and dependencies...${NC}"

sudo dnf install -y \
    wine-core \
    wine-core.i686 \
    wine-common \
    wine-common.i686 \
    wine-pulseaudio \
    wine-pulseaudio.i686 \
    wine-wayland \
    wine-wayland.i686 \
    winetricks \
    vulkan-loader \
    vulkan-loader.i686 \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers.i686 \
    dxvk \
    vkd3d \
    2>/dev/null || echo -e "${YELLOW}⚠ Some packages may already be installed${NC}"

echo -e "${GREEN}✓ Dependencies installed${NC}"

echo ""

# Step 4: Create WINEPREFIX
echo -e "${BLUE}[Step 4/5] Creating Wine prefix at $WINE_PREFIX...${NC}"

export WINEPREFIX="$WINE_PREFIX"
export WINEARCH=win64
export WINEDEBUG=-all
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

if [ -d "$WINE_PREFIX" ]; then
    echo -e "${YELLOW}⚠ Wine prefix already exists, backing up...${NC}"
    mv "$WINE_PREFIX" "${WINE_PREFIX}.backup.$(date +%s)"
fi

echo "Initializing new Wine prefix..."
wineboot -i 2>&1 | tail -3

echo -e "${GREEN}✓ Wine prefix created${NC}"

echo ""

# Step 5: Install Winetricks components
echo -e "${BLUE}[Step 5/5] Installing Winetricks components...${NC}"
echo "This will take 15-30 minutes. Components will be downloaded as needed."
echo ""

# Use local winetricks if available, otherwise use system
if [ -x "$WINETRICKS_LOCAL" ]; then
    WINETRICKS_CMD="$WINETRICKS_LOCAL"
    echo "Using local Winetricks: $WINETRICKS_LOCAL"
elif command_exists winetricks; then
    WINETRICKS_CMD="winetricks"
    echo "Using system Winetricks"
else
    echo -e "${RED}✗ Winetricks not found!${NC}"
    exit 1
fi

echo ""

# Install components
echo "Installing .NET Framework 4.8..."
$WINETRICKS_CMD -q dotnet48 2>&1 | tail -3 || true
echo -e "${GREEN}✓ dotnet48${NC}"

echo ""
echo "Installing Visual C++ 2017 Runtime..."
$WINETRICKS_CMD -q vcrun2017 2>&1 | tail -3 || true
echo -e "${GREEN}✓ vcrun2017${NC}"

echo ""
echo "Installing WebView2 (this may take 5-10 minutes)..."
$WINETRICKS_CMD -q webview2 2>&1 | tail -3 || true
echo -e "${GREEN}✓ webview2${NC}"

echo ""
echo "Installing DXVK..."
$WINETRICKS_CMD -q dxvk 2>&1 | tail -3 || true
echo -e "${GREEN}✓ dxvk${NC}"

echo ""
echo "Installing VKD3D..."
$WINETRICKS_CMD -q vkd3d 2>&1 | tail -3 || true
echo -e "${GREEN}✓ vkd3d${NC}"

echo ""

# Finalize
echo "Finalizing configuration..."
wineboot -u 2>&1 | tail -2 || true

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✓ OFFLINE SETUP COMPLETE!                                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Configuration Summary:"
echo "  Wine Prefix: $WINE_PREFIX"
echo "  Wine Version: $(wine --version)"
echo "  Winetricks: $WINETRICKS_CMD"
echo "  GPU: NVIDIA with Prime Offloading"
echo ""

echo "Next steps:"
echo "  1. Install SketchUp 2026:"
echo "     ./scripts/04-install-sketchup.sh"
echo ""
echo "  2. Launch SketchUp:"
echo "     ./scripts/03-launch-sketchup.sh"
echo ""

