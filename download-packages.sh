#!/bin/bash
##############################################################################
# Download Manager for SketchUp 2026 Wine Offline Package
# This script downloads all required software to the packages/ directory
# Run this ONCE in the container to populate all packages
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PACKAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/packages" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Package Download Manager - Offline Setup                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to download
download_file() {
    local url="$1"
    local dest="$2"
    local name="$3"
    
    if [ -f "$dest" ]; then
        echo -e "${GREEN}✓ Already exists: $name${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}⬇ Downloading: $name${NC}"
    if wget -q --show-progress "$url" -O "$dest" 2>&1; then
        echo -e "${GREEN}✓ Downloaded: $name${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to download: $name${NC}"
        return 1
    fi
}

# ============================================================================
# Download Winetricks
# ============================================================================
echo -e "${BLUE}[1/4] Downloading Winetricks...${NC}"
download_file \
    "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" \
    "$PACKAGES_DIR/tools/winetricks" \
    "Winetricks Script"

if [ -f "$PACKAGES_DIR/tools/winetricks" ]; then
    chmod +x "$PACKAGES_DIR/tools/winetricks"
    echo -e "${GREEN}✓ Winetricks is executable${NC}"
fi

echo ""

# ============================================================================
# Download Wine Stable Packages (if available)
# ============================================================================
echo -e "${BLUE}[2/4] Downloading Wine Stable for Fedora 42...${NC}"
echo -e "${YELLOW}Note: Wine must be obtained from official WineHQ repositories${NC}"
echo "Attempting to download Wine packages..."

# Try Fedora 42 Wine packages
WINE_URLS=(
    "https://dl.winehq.org/wine-builds/fedora/42/x86_64/wine-stable-10.0-1.fc42.x86_64.rpm"
    "https://dl.winehq.org/wine-builds/fedora/42/x86_64/wine-common-10.0-1.fc42.noarch.rpm"
)

for url in "${WINE_URLS[@]}"; do
    filename=$(basename "$url")
    download_file "$url" "$PACKAGES_DIR/wine/$filename" "$filename" || true
done

echo ""

# ============================================================================
# Download Winetricks Components (Windows installers for Wine)
# ============================================================================
echo -e "${BLUE}[3/4] Downloading Winetricks Components...${NC}"
echo -e "${YELLOW}These are Windows installers that run inside Wine${NC}"
echo ""

# Note: These are very large and hosted on various locations
echo -e "${YELLOW}⚠ Component downloads are hosted on various CDNs${NC}"
echo "Some components may need to be downloaded manually from Winetricks cache"
echo ""

# DXVK and VKD3D are typically compiled locally or obtained from GitHub
echo -e "${YELLOW}Creating winetricks-components directory...${NC}"
mkdir -p "$PACKAGES_DIR/winetricks-components/"{dotnet48,vcrun2017,webview2,dxvk,vkd3d}

echo -e "${YELLOW}Note: Winetricks components are downloaded on-demand by winetricks${NC}"
echo "The actual .msi/.exe files are cached in ~/.cache/winetricks after first installation"
echo ""

# ============================================================================
# Download Additional Tools
# ============================================================================
echo -e "${BLUE}[4/4] Downloading Additional Tools...${NC}"

# Download RPM Fusion repositories for multimedia support
echo "Creating RPM Fusion repository files..."

cat > "$PACKAGES_DIR/tools/rpmfusion-setup.txt" << 'RPMFUSION'
RPM Fusion Repositories for Fedora 42:

Free repository:
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm

Non-free repository:
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm

These can be installed with:
  sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm
  sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm

Or downloaded and installed locally on Fedora 42.
RPMFUSION

echo -e "${GREEN}✓ Created RPM Fusion reference${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Download Summary                                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Downloaded to: $PACKAGES_DIR"
echo ""
echo "Packages included:"
echo "  ✓ Winetricks (tools/winetricks)"

if [ -f "$PACKAGES_DIR/wine"/*.rpm ]; then
    echo "  ✓ Wine RPM packages (wine/)"
else
    echo "  ! Wine RPM packages (may not be available)"
fi

echo ""
echo "Next Steps:"
echo "  1. Copy this entire repository to your Fedora 42 machine"
echo "  2. Run: ./sketchup-wine-setup/scripts/00-master-setup-offline.sh"
echo "  3. The script will use local packages when available"
echo ""

