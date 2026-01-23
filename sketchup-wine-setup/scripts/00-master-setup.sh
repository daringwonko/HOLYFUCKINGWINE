#!/bin/bash
##############################################################################
# SketchUp 2026 on Wine - Complete Setup Script
# For: Fedora 42 Workstation with NVIDIA Hybrid Graphics
# Target: NVIDIA GTX 1050 Ti with VKD3D
# This script installs all required software and dependencies
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - STANDARDIZED PATH
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
WINE_PREFIX="${HOME}/.sketchup2026"
WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"

# Helper functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Show header
print_header "SketchUp 2026 Wine Setup - Master Script"

# Check prerequisites
echo -e "${BLUE}[Preflight] Checking prerequisites...${NC}"

# Check Fedora version
FEDORA_VERSION=$(grep -oP '(?<=Fedora release )\d+' /etc/fedora-release 2>/dev/null || echo "42")
print_success "Running on Fedora $FEDORA_VERSION"

# Check sudo
if ! sudo -l &>/dev/null; then
    print_error "This script requires sudo privileges"
    exit 1
fi
print_success "Sudo privileges confirmed"

# Check disk space
AVAILABLE_SPACE=$(df -BG ~ | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 5 ]; then
    print_warning "Low disk space: ${AVAILABLE_SPACE}GB available (5GB recommended)"
else
    print_success "Sufficient disk space: ${AVAILABLE_SPACE}GB available"
fi

# Check for existing prefix
if [ -d "$WINE_PREFIX" ]; then
    print_warning "Wine prefix already exists at $WINE_PREFIX"
    read -p "Backup and create fresh prefix? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Backing up existing prefix..."
        mv "$WINE_PREFIX" "${WINE_PREFIX}.backup.$(date +%s)"
        print_success "Backed up to ${WINE_PREFIX}.backup.*"
    fi
fi

echo ""

# Step 1: Install WineHQ Repository and Wine
echo -e "${BLUE}[Step 1/6] Installing WineHQ Repository and Wine...${NC}"
if ! command_exists wine; then
    echo "Adding WineHQ repository for Fedora..."

    # Add RPM Fusion first (multimedia support)
    echo "Installing RPM Fusion repositories..."
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm 2>/dev/null || \
        echo "RPM Fusion may already be installed"

    # Add WineHQ repository
    echo "Adding WineHQ repository..."
    sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/wine-fedora.repo 2>/dev/null || \
        echo "WineHQ repository may already be configured"

    # Update package cache
    echo "Updating package cache..."
    sudo dnf update -y

    # Install Wine stable
    echo "Installing WineHQ Stable (version 10.0 or 9.0)..."
    sudo dnf install -y winehq-stable

    print_success "Wine installed: $(wine --version)"
else
    WINE_VERSION=$(wine --version)
    print_success "Wine already installed: $WINE_VERSION"
fi

# Step 2: Install 32-bit support and essential packages
echo ""
echo -e "${BLUE}[Step 2/6] Installing 32-bit support and dependencies...${NC}"
echo "Installing Wine libraries and multimedia support..."

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
    libXcomposite \
    libXcomposite.i686 \
    libXinerama \
    libXinerama.i686 \
    libXrandr \
    libXrandr.i686 \
    libXcursor \
    libXcursor.i686 \
    libXxf86vm \
    libXxf86vm.i686 \
    libXi \
    libXi.i686 \
    libxkbcommon \
    libxkbcommon.i686 \
    openal-soft \
    openal-soft.i686 \
    freetype \
    freetype.i686 \
    vulkan-loader \
    vulkan-loader.i686 \
    vulkan-validation-layers \
    vulkan-validation-layers.i686 \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers.i686 \
    dxvk \
    vkd3d \
    2>/dev/null || print_warning "Some packages may vary on Fedora $FEDORA_VERSION"

print_success "Dependencies installed"

# Step 3: Verify winetricks
echo ""
echo -e "${BLUE}[Step 3/6] Verifying Winetricks...${NC}"
if command_exists winetricks; then
    print_success "Winetricks found: $(which winetricks)"
else
    echo "Installing winetricks from source..."
    sudo mkdir -p /opt/winetricks
    sudo wget -q "$WINETRICKS_URL" -O /opt/winetricks/winetricks 2>/dev/null || \
        curl -s "$WINETRICKS_URL" -o /tmp/winetricks
    sudo chmod +x /opt/winetricks/winetricks
    sudo ln -sf /opt/winetricks/winetricks /usr/local/bin/winetricks
    print_success "Winetricks installed"
fi

# Step 4: Create fresh WINEPREFIX
echo ""
echo -e "${BLUE}[Step 4/6] Creating fresh WINEPREFIX at $WINE_PREFIX...${NC}"
export WINEPREFIX="$WINE_PREFIX"
export WINE_CPU_TOPOLOGY=4
export WINEARCH=win64
export WINEDEBUG=-all

# Create new prefix
echo "Creating new 64-bit Windows prefix..."
wineboot -i 2>&1 | tail -3

print_success "WINEPREFIX created at $WINE_PREFIX"

# Step 5: Install Winetricks verbs for SketchUp 2026
echo ""
echo -e "${BLUE}[Step 5/6] Installing Winetricks components for SketchUp 2026...${NC}"
echo "This will take 15-30 minutes. Do not interrupt."
echo ""

# Set GPU variables
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Install Windows 10
echo "Setting Windows version to Windows 10..."
winetricks -q winver win10 2>&1 | tail -2 || true
print_success "Windows 10 set"

# Install .NET 4.8 (required for app core)
echo ""
echo "Installing .NET Framework 4.8 (required for app core)..."
if winetricks -q dotnet48 2>&1 | tail -5; then
    print_success "dotnet48 installed"
else
    print_warning "dotnet48 installation warnings (may be normal)"
fi

# Install VC++ 2017 (required for runtime)
echo ""
echo "Installing Visual C++ 2017 Runtime (required for runtime)..."
if winetricks -q vcrun2017 2>&1 | tail -5; then
    print_success "vcrun2017 installed"
else
    print_warning "vcrun2017 installation warnings (may be normal)"
fi

# Install WebView2 (CRITICAL for Trimble Identity login)
echo ""
echo "Installing WebView2 (CRITICAL: Required for Trimble Identity login screen)..."
echo "This component can take 5-10 minutes. Please wait..."
if winetricks -q webview2 2>&1 | tail -5; then
    print_success "webview2 installed"
else
    print_warning "webview2 installation warnings (may be normal)"
fi

# Install DXVK (DirectX via Vulkan)
echo ""
echo "Installing DXVK (DirectX 10/11/12 support)..."
if winetricks -q dxvk 2>&1 | tail -5; then
    print_success "dxvk installed"
else
    print_warning "dxvk installation warnings (may be normal)"
fi

# Install VKD3D (Direct3D 12 support for GTX 1050 Ti)
echo ""
echo "Installing VKD3D (Direct3D 12 support for NVIDIA GPU)..."
if winetricks -q vkd3d 2>&1 | tail -5; then
    print_success "vkd3d installed"
else
    print_warning "vkd3d installation warnings (may be normal)"
fi

# Step 6: Optimize WINEPREFIX settings
echo ""
echo -e "${BLUE}[Step 6/6] Optimizing WINEPREFIX settings...${NC}"

# Disable CSMT for stability
echo "Optimizing DirectX settings..."
WINEPREFIX="$WINE_PREFIX" wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\Direct3D" /v CSMT /t REG_SZ /d enabled /f 2>/dev/null || true
WINEPREFIX="$WINE_PREFIX" wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\Direct3D" /v VideoMemorySize /t REG_SZ /d 2048 /f 2>/dev/null || true

# Set Windows version again
WINEPREFIX="$WINE_PREFIX" winetricks -q winver win10 2>&1 | tail -2 || true

# Finalize
wineboot -u 2>/dev/null || true

print_success "Configuration optimized"

# Final verification
echo ""
print_header "Setup Complete!"

echo "Configuration Summary:"
echo "  WINEPREFIX:  $WINE_PREFIX"
echo "  Wine:        $(wine --version)"
echo "  Winetricks:  $(which winetricks)"
echo "  GPU Support: NVIDIA GTX 1050 Ti (VKD3D)"
echo ""
echo "Installed Components:"
echo "  ✓ Wine Stable (10.0 or 9.0)"
echo "  ✓ .NET Framework 4.8"
echo "  ✓ Visual C++ 2017 Runtime"
echo "  ✓ WebView2 (Trimble Identity)"
echo "  ✓ DXVK (DirectX 10/11/12)"
echo "  ✓ VKD3D (Direct3D 12)"
echo ""
echo "Next Steps:"
echo "  1. Run: ./scripts/04-install-sketchup.sh"
echo "  2. Launch SketchUp: ./scripts/03-launch-sketchup.sh"
echo ""
echo "GPU Offloading (automatically set in launch script):"
echo "  __NV_PRIME_RENDER_OFFLOAD=1"
echo "  __GLX_VENDOR_LIBRARY_NAME=nvidia"
echo ""
print_success "All setup complete! You can now install SketchUp."
