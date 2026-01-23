#!/bin/bash
# WINEPREFIX Setup Script for SketchUp 2026
# Creates a clean 64-bit Wine prefix and installs all required dependencies

set -e

# Configuration - STANDARDIZED PATH (matches all other scripts)
export WINEPREFIX="$HOME/.sketchup2026"
export WINEARCH=win64
export WINEDEBUG=-all

# GPU Offloading for NVIDIA
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

echo "=== SketchUp 2026 Wine Prefix Setup ==="
echo ""
echo "Configuration:"
echo "  WINEPREFIX: $WINEPREFIX"
echo "  WINEARCH: $WINEARCH"
echo "  GPU Offloading: NVIDIA GTX 1050 Ti"
echo ""

# Check if wine is installed
if ! command -v wine &> /dev/null; then
    echo "ERROR: Wine is not installed. Please run 01-install-winehq.sh first"
    exit 1
fi

echo "Wine version:"
wine --version
echo ""

# Check if winetricks is installed
if ! command -v winetricks &> /dev/null; then
    echo "ERROR: winetricks is not installed. Please run 01-install-winehq.sh first"
    exit 1
fi

echo "Step 1: Creating clean WINEPREFIX at $WINEPREFIX..."
# Initialize the prefix - wine will create directory structure automatically
# The -init flag forces reinitialization if it already exists
wineboot -i

echo ""
echo "Step 2: Setting Windows version to Windows 10..."
# Set to Windows 10 for better compatibility with SketchUp 2026
winetricks winver win10

echo ""
echo "Step 3: Installing required .NET Framework (dotnet48)..."
winetricks dotnet48

echo ""
echo "Step 4: Installing Visual C++ Runtime 2017 (vcrun2017)..."
winetricks vcrun2017

echo ""
echo "Step 5: Installing WebView2 (CRITICAL for Trimble Identity login)..."
winetricks webview2

echo ""
echo "Step 6: Installing DirectX components (dxvk for D3D12)..."
# DXVK provides Direct3D 10, 11, and 12 via Vulkan
winetricks dxvk

echo ""
echo "Step 7: Installing Direct3D 3D components (vkd3d for D3D12)..."
# VKD3D provides additional D3D12 support
winetricks vkd3d

echo ""
echo "Step 8: Final configuration and cleanup..."
# Ensure GPU offloading is set
wineboot -u

echo ""
echo "=== WINEPREFIX Setup Complete ==="
echo ""
echo "Prefix created at: $WINEPREFIX"
echo "All required dependencies installed:"
echo "  ✓ dotnet48 (App core)"
echo "  ✓ vcrun2017 (Runtime)"
echo "  ✓ webview2 (Trimble Identity login)"
echo "  ✓ dxvk (DirectX via Vulkan)"
echo "  ✓ vkd3d (D3D12 support)"
echo ""
echo "Next step: Use 03-launch-sketchup.sh to run SketchUp 2026"
echo ""
echo "IMPORTANT: Keep the WINEPREFIX at: $WINEPREFIX"
echo "When transferring to another system, copy the entire ~/.sketchup2026 directory"
