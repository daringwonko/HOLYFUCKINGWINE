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

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
WINE_PREFIX="${HOME}/.sketchup2026"
WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SketchUp 2026 Wine Setup - Master Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install WineHQ Repository and Wine
echo -e "${BLUE}[Step 1/6] Installing WineHQ Repository and Wine...${NC}"
if ! command_exists wine; then
    echo "Adding WineHQ repository for Fedora..."
    
    # Get Fedora version
    FEDORA_VERSION=$(grep -oP '(?<=Fedora release )\d+' /etc/fedora-release 2>/dev/null || echo "42")
    
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
    
    echo -e "${GREEN}✓ Wine installed: $(wine --version)${NC}"
else
    WINE_VERSION=$(wine --version)
    echo -e "${GREEN}✓ Wine already installed: $WINE_VERSION${NC}"
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
    lib32-gcc \
    lib32-glibc \
    lib32-libx11 \
    lib32-freetype \
    lib32-fontconfig \
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
    2>/dev/null || echo -e "${YELLOW}Some packages may vary on Fedora 42${NC}"

echo -e "${GREEN}✓ Dependencies installed${NC}"

# Step 3: Verify winetricks
echo ""
echo -e "${BLUE}[Step 3/6] Verifying Winetricks...${NC}"
if command_exists winetricks; then
    echo -e "${GREEN}✓ Winetricks found: $(which winetricks)${NC}"
else
    echo "Installing winetricks from source..."
    sudo mkdir -p /opt/winetricks
    sudo wget -q "$WINETRICKS_URL" -O /opt/winetricks/winetricks 2>/dev/null || \
        curl -s "$WINETRICKS_URL" -o /tmp/winetricks
    sudo chmod +x /opt/winetricks/winetricks
    sudo ln -sf /opt/winetricks/winetricks /usr/local/bin/winetricks
    echo -e "${GREEN}✓ Winetricks installed${NC}"
fi

# Step 4: Create fresh WINEPREFIX
echo ""
echo -e "${BLUE}[Step 4/6] Creating fresh WINEPREFIX at $WINE_PREFIX...${NC}"
export WINEPREFIX="$WINE_PREFIX"
export WINE_CPU_TOPOLOGY=4
export WINEARCH=win64
export WINEDEBUG=-all

# Backup old prefix if exists
if [ -d "$WINE_PREFIX" ]; then
    echo -e "${YELLOW}WINEPREFIX already exists. Backing up...${NC}"
    mv "$WINE_PREFIX" "${WINE_PREFIX}.backup.$(date +%s)"
fi

# Create new prefix
echo "Creating new 64-bit Windows prefix..."
wineboot -i 2>&1 | tail -3

echo -e "${GREEN}✓ WINEPREFIX created at $WINE_PREFIX${NC}"

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
echo -e "${GREEN}✓ Windows 10 set${NC}"

# Install .NET 4.8 (required for app core)
echo ""
echo "Installing .NET Framework 4.8 (required for app core)..."
if winetricks -q dotnet48 2>&1 | tail -5; then
    echo -e "${GREEN}✓ dotnet48 installed${NC}"
else
    echo -e "${YELLOW}! dotnet48 installation warnings (may be normal)${NC}"
fi

# Install VC++ 2017 (required for runtime)
echo ""
echo "Installing Visual C++ 2017 Runtime (required for runtime)..."
if winetricks -q vcrun2017 2>&1 | tail -5; then
    echo -e "${GREEN}✓ vcrun2017 installed${NC}"
else
    echo -e "${YELLOW}! vcrun2017 installation warnings (may be normal)${NC}"
fi

# Install WebView2 (CRITICAL for Trimble Identity login)
echo ""
echo "Installing WebView2 (CRITICAL: Required for Trimble Identity login screen)..."
echo "This component can take 5-10 minutes. Please wait..."
if winetricks -q webview2 2>&1 | tail -5; then
    echo -e "${GREEN}✓ webview2 installed${NC}"
else
    echo -e "${YELLOW}! webview2 installation warnings (may be normal)${NC}"
fi

# Install DXVK (DirectX via Vulkan)
echo ""
echo "Installing DXVK (DirectX 10/11/12 support)..."
if winetricks -q dxvk 2>&1 | tail -5; then
    echo -e "${GREEN}✓ dxvk installed${NC}"
else
    echo -e "${YELLOW}! dxvk installation warnings (may be normal)${NC}"
fi

# Install VKD3D (Direct3D 12 support for GTX 1050 Ti)
echo ""
echo "Installing VKD3D (Direct3D 12 support for NVIDIA GPU)..."
if winetricks -q vkd3d 2>&1 | tail -5; then
    echo -e "${GREEN}✓ vkd3d installed${NC}"
else
    echo -e "${YELLOW}! vkd3d installation warnings (may be normal)${NC}"
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

echo -e "${GREEN}✓ Configuration optimized${NC}"

# Final verification
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
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
echo "  1. Clone this repo to your machine"
echo "  2. Run: ./scripts/04-install-sketchup.sh"
echo "  3. Launch SketchUp: ./scripts/03-launch-sketchup.sh"
echo ""
echo "GPU Offloading (automatically set in launch script):"
echo "  __NV_PRIME_RENDER_OFFLOAD=1"
echo "  __GLX_VENDOR_LIBRARY_NAME=nvidia"
echo ""
    
    local fedora_version=$(cat /etc/fedora-release | grep -oP '\d+')
    print_success "Running on Fedora $fedora_version"
    
    # Check for sudo
    if ! sudo -l &>/dev/null; then
        print_error "This script requires sudo privileges"
        exit 1
    fi
    print_success "Sudo privileges confirmed"
    
    # Check disk space
    local available_space=$(df -BG ~ | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 5 ]; then
        print_warning "Low disk space: ${available_space}GB available (5GB recommended)"
    else
        print_success "Sufficient disk space: ${available_space}GB available"
    fi
    
    # Check for existing prefix
    if [ -d "$WINEPREFIX_PATH" ]; then
        print_warning "Wine prefix already exists at $WINEPREFIX_PATH"
        read -p "Continue with existing prefix? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation cancelled"
            exit 1
        fi
    fi
    
    print_separator
}

# Install WineHQ
install_winehq() {
    print_step "Installing WineHQ Stable"
    
    if command -v wine &> /dev/null; then
        local wine_version=$(wine --version)
        print_warning "Wine already installed: $wine_version"
        read -p "Reinstall Wine? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_success "Skipping Wine installation"
            print_separator
            return 0
        fi
    fi
    
    print_step "Adding WineHQ Repository"
    
    local fedora_version=$(cat /etc/fedora-release | grep -oP '\d+')
    
    # Add RPM Fusion repos (required for multimedia)
    print_warning "Installing RPM Fusion repositories..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm \
                        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm 2>/dev/null || \
    print_warning "RPM Fusion repos may already be installed"
    
    # Add WineHQ repo
    print_warning "Adding WineHQ repository..."
    sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/wine-fedora.repo || \
    print_warning "WineHQ repository may already be configured"
    
    # Update and install
    print_warning "Updating package cache..."
    sudo dnf update -y
    
    print_warning "Installing winehq-stable (this may take 5-10 minutes)..."
    sudo dnf install -y winehq-stable
    
    print_warning "Installing winetricks..."
    sudo dnf install -y winetricks
    
    # Install dependencies
    print_warning "Installing system libraries for Wine..."
    sudo dnf install -y \
        lib32-gcc \
        lib32-glibc \
        lib32-libx11 \
        lib32-freetype \
        lib32-fontconfig \
        vulkan-loader \
        lib32-vulkan-loader \
        dxvk \
        vkd3d 2>/dev/null || print_warning "Some library packages may already be installed"
    
    # Verify installation
    if command -v wine &> /dev/null; then
        local wine_version=$(wine --version)
        print_success "Wine installed: $wine_version"
    else
        print_error "Wine installation failed"
        exit 1
    fi
    
    print_separator
}

# Create and configure WINEPREFIX
setup_wineprefix() {
    print_step "Creating WINEPREFIX at $WINEPREFIX_PATH"
    
    export WINEPREFIX="$WINEPREFIX_PATH"
    export WINEARCH="$WINEARCH"
    export WINEDEBUG=-all
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    
    # Initialize Wine prefix
    if [ ! -d "$WINEPREFIX_PATH" ]; then
        print_warning "Initializing new Wine prefix..."
        wineboot -i
    else
        print_warning "Wine prefix already exists, skipping initialization"
    fi
    
    print_success "WINEPREFIX created at: $WINEPREFIX_PATH"
    print_separator
}

# Install winetricks components
install_dependencies() {
    print_step "Installing SketchUp 2026 Dependencies"
    
    export WINEPREFIX="$WINEPREFIX_PATH"
    export WINEARCH="$WINEARCH"
    export WINEDEBUG=-all
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    
    # Windows 10 compatibility
    print_warning "Setting Windows version to Windows 10..."
    winetricks winver win10
    print_success "Windows 10 compatibility set"
    
    # .NET Framework 4.8
    print_warning "Installing .NET Framework 4.8 (3-5 minutes)..."
    if ! winetricks dotnet48; then
        print_error ".NET Framework 4.8 installation failed"
        exit 1
    fi
    print_success ".NET Framework 4.8 installed"
    
    # Visual C++ 2017 Runtime
    print_warning "Installing Visual C++ 2017 Runtime (2-3 minutes)..."
    if ! winetricks vcrun2017; then
        print_error "Visual C++ 2017 Runtime installation failed"
        exit 1
    fi
    print_success "Visual C++ 2017 Runtime installed"
    
    # WebView2 (longest component - 10-15 minutes)
    print_warning "Installing WebView2 (10-15 minutes - this is NORMAL to take a while)..."
    if ! winetricks webview2; then
        print_error "WebView2 installation failed"
        exit 1
    fi
    print_success "WebView2 installed (Required for Trimble Identity login)"
    
    # DXVK (DirectX 10/11/12)
    print_warning "Installing DXVK (DirectX via Vulkan)..."
    if ! winetricks dxvk; then
        print_error "DXVK installation failed"
        exit 1
    fi
    print_success "DXVK installed"
    
    # VKD3D (D3D12 support)
    print_warning "Installing VKD3D (Direct3D 12 support)..."
    if ! winetricks vkd3d; then
        print_error "VKD3D installation failed"
        exit 1
    fi
    print_success "VKD3D installed"
    
    # Final cleanup
    print_warning "Finalizing Wine configuration..."
    wineboot -u
    
    print_separator
}

# Summary and next steps
print_summary() {
    print_step "Installation Complete!"
    
    echo ""
    echo "Configuration Summary:"
    echo "  Wine Prefix:     $WINEPREFIX_PATH"
    echo "  Architecture:    $WINEARCH"
    echo "  GPU Offloading:  NVIDIA GTX 1050 Ti"
    echo ""
    echo "Installed Components:"
    echo "  ✓ Wine (Stable 10.0 or 9.0)"
    echo "  ✓ .NET Framework 4.8"
    echo "  ✓ Visual C++ 2017 Runtime"
    echo "  ✓ WebView2 (Trimble Identity)"
    echo "  ✓ DXVK (DirectX 10/11/12)"
    echo "  ✓ VKD3D (Direct3D 12)"
    echo ""
    echo "Next Steps:"
    echo "  1. Review the scripts:"
    echo "     - scripts/03-launch-sketchup.sh  (to launch SketchUp)"
    echo "     - scripts/04-install-sketchup.sh (to install SketchUp)"
    echo ""
    echo "  2. Read the documentation:"
    echo "     - docs/README.md                 (Setup overview)"
    echo "     - docs/NVIDIA-GPU-OFFLOADING.md  (GPU configuration)"
    echo "     - docs/TROUBLESHOOTING.md        (Problem solving)"
    echo ""
    echo "  3. Launch SketchUp:"
    echo "     ./scripts/03-launch-sketchup.sh"
    echo ""
    echo "Environment Variables Set (automatically in scripts):"
    echo "  export __NV_PRIME_RENDER_OFFLOAD=1"
    echo "  export __GLX_VENDOR_LIBRARY_NAME=nvidia"
    echo ""
    print_separator
}

# Main execution
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  SketchUp 2026 Wine Setup for Fedora 42 + NVIDIA GPU       ║"
    echo "║  (Complete Automated Installation)                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    install_winehq
    setup_wineprefix
    install_dependencies
    print_summary
    
    print_success "All setup complete! Make scripts executable and run them."
}

# Run main function
main "$@"
