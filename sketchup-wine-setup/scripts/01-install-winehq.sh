#!/bin/bash
# WineHQ Stable Installation Script for Fedora 42
# Installs Wine 10.0 or 9.0 from official WineHQ repository
# This script must be run with sudo/root privileges

set -e

echo "=== WineHQ Stable Installation for Fedora 42 ==="
echo "This script will add the WineHQ repository and install wine-stable."
echo ""

# Detect Fedora version
FEDORA_VERSION=$(cat /etc/fedora-release | grep -oP '\d+')
echo "Detected Fedora version: $FEDORA_VERSION"

# Check if running as root/sudo
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run with sudo privileges"
   exit 1
fi

echo ""
echo "Step 1: Adding WineHQ repository..."

# Enable RPM Fusion repositories (required for multimedia codecs)
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
                https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm || \
echo "Note: RPM Fusion repos may already be installed"

# Add WineHQ repository
dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/wine-fedora.repo

echo ""
echo "Step 2: Updating package cache..."
dnf update -y

echo ""
echo "Step 3: Installing wine-stable (winehq-stable)..."
# Install wine-stable - this will get the latest stable version (10.0 or 9.0)
dnf install -y winehq-stable

echo ""
echo "Step 4: Installing additional dependencies..."
# Install winetricks for managing Wine components
dnf install -y winetricks

# Install required system libraries for SketchUp
dnf install -y \
    lib32-gcc \
    lib32-glibc \
    lib32-libx11 \
    lib32-freetype \
    lib32-fontconfig \
    vulkan-loader \
    lib32-vulkan-loader \
    dxvk \
    vkd3d

echo ""
echo "Step 5: Verifying installation..."
wine --version
winetricks --version

echo ""
echo "=== WineHQ Installation Complete ==="
echo ""
echo "Wine has been installed to: $(which wine)"
echo "Wine version:"
wine --version
echo ""
echo "Next step: Run 02-setup-wineprefix.sh to configure the WINEPREFIX"
