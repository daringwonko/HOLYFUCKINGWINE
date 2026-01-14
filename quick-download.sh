#!/bin/bash
##############################################################################
# Quick Download - SketchUp 2026 Wine Offline Packages
# Run this to download all available components
##############################################################################

set -e

PACKAGES_DIR="/workspaces/HOLYFUCKINGWINE/packages"

echo "============================================================"
echo "Downloading SketchUp 2026 Wine Packages"
echo "============================================================"
echo ""

# Create directories
mkdir -p "$PACKAGES_DIR/tools"
mkdir -p "$PACKAGES_DIR/wine"
mkdir -p "$PACKAGES_DIR/winetricks-components"

echo "[1/3] Downloading Winetricks..."
if wget -q --show-progress \
    "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" \
    -O "$PACKAGES_DIR/tools/winetricks" 2>&1; then
    chmod +x "$PACKAGES_DIR/tools/winetricks"
    echo "✓ Winetricks downloaded"
else
    echo "! Could not download Winetricks (may require internet connection)"
fi

echo ""
echo "[2/3] Downloading Wine Stable for Fedora 42..."
echo "Attempting to download Wine RPM packages..."

# Try to download Wine packages (might fail due to network)
echo "Trying wine-stable..."
wget -q --show-progress \
    "https://dl.winehq.org/wine-builds/fedora/42/x86_64/wine-stable-10.0-1.fc42.x86_64.rpm" \
    -O "$PACKAGES_DIR/wine/wine-stable-10.0-1.fc42.x86_64.rpm" 2>&1 || \
    echo "! wine-stable could not be downloaded"

echo "Trying wine-common..."
wget -q --show-progress \
    "https://dl.winehq.org/wine-builds/fedora/42/x86_64/wine-common-10.0-1.fc42.noarch.rpm" \
    -O "$PACKAGES_DIR/wine/wine-common-10.0-1.fc42.noarch.rpm" 2>&1 || \
    echo "! wine-common could not be downloaded"

echo ""
echo "[3/3] Creating reference files..."

cat > "$PACKAGES_DIR/tools/rpmfusion-setup.txt" << 'EOF'
RPM Fusion Repositories for Fedora 42:

Free repository:
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm

Non-free repository:
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm

These can be installed with:
  sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm
  sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm

Or downloaded and installed locally on Fedora 42.
EOF

echo "✓ Reference files created"

echo ""
echo "============================================================"
echo "Download Summary"
echo "============================================================"
echo ""
echo "Downloaded to: $PACKAGES_DIR"
echo ""

if [ -f "$PACKAGES_DIR/tools/winetricks" ]; then
    echo "✓ Winetricks available"
else
    echo "! Winetricks not available"
fi

if ls "$PACKAGES_DIR/wine"/*.rpm >/dev/null 2>&1; then
    echo "✓ Wine RPM packages downloaded:"
    ls -lh "$PACKAGES_DIR/wine"/*.rpm
else
    echo "! Wine RPM packages not available (will use DNF)"
fi

echo ""
echo "Directory structure:"
find "$PACKAGES_DIR" -type f | sort
echo ""

echo "Total size of downloads:"
du -sh "$PACKAGES_DIR"
echo ""

echo "Next: Transfer this repository to your Fedora 42 machine"
echo "Then run: ./sketchup-wine-setup/scripts/00-master-setup-offline.sh"

