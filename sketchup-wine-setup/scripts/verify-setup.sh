#!/bin/bash
##############################################################################
# Environment Setup Verification Script
# Run this to check if all components are properly installed
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SketchUp 2026 Wine Environment - Verification Report     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

WINE_PREFIX="${HOME}/.sketchup2026"
ISSUES=0
WARNINGS=0

# Check 1: Wine Installation
echo -e "${BLUE}[Check 1/10] Wine Installation${NC}"
if command -v wine &> /dev/null; then
    WINE_VERSION=$(wine --version)
    echo -e "${GREEN}✓ Wine is installed${NC}"
    echo "  Version: $WINE_VERSION"
    
    # Check version is 9.0 or 10.0
    if echo "$WINE_VERSION" | grep -qE "(9\.|10\.)" ; then
        echo -e "${GREEN}✓ Wine version is correct (9.x or 10.x)${NC}"
    else
        echo -e "${YELLOW}⚠ Wine version is $(echo "$WINE_VERSION" | grep -oE '[0-9]+\.[0-9]+'), expected 9.x or 10.x${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}✗ Wine is not installed${NC}"
    echo "  Run: ./scripts/00-master-setup.sh"
    ((ISSUES++))
fi
echo ""

# Check 2: WINEPREFIX
echo -e "${BLUE}[Check 2/10] WINEPREFIX at $WINE_PREFIX${NC}"
if [ -d "$WINE_PREFIX" ]; then
    SIZE=$(du -sh "$WINE_PREFIX" 2>/dev/null | cut -f1)
    echo -e "${GREEN}✓ WINEPREFIX exists${NC}"
    echo "  Size: $SIZE"
else
    echo -e "${RED}✗ WINEPREFIX not found${NC}"
    echo "  Run: ./scripts/00-master-setup.sh"
    ((ISSUES++))
fi
echo ""

# Check 3: Winetricks
echo -e "${BLUE}[Check 3/10] Winetricks${NC}"
if command -v winetricks &> /dev/null; then
    echo -e "${GREEN}✓ Winetricks is installed${NC}"
    echo "  Location: $(which winetricks)"
else
    echo -e "${RED}✗ Winetricks not found${NC}"
    ((ISSUES++))
fi
echo ""

# Check 4: .NET Framework 4.8
echo -e "${BLUE}[Check 4/10] .NET Framework 4.8${NC}"
if [ -d "$WINE_PREFIX" ]; then
    export WINEPREFIX="$WINE_PREFIX"
    if wine reg query "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full" 2>/dev/null | grep -q "Release"; then
        echo -e "${GREEN}✓ .NET Framework 4.8 is installed${NC}"
    else
        echo -e "${YELLOW}⚠ .NET Framework 4.8 may not be installed${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (WINEPREFIX not found)${NC}"
    ((WARNINGS++))
fi
echo ""

# Check 5: WebView2
echo -e "${BLUE}[Check 5/10] WebView2${NC}"
if [ -d "$WINE_PREFIX" ]; then
    export WINEPREFIX="$WINE_PREFIX"
    if wine reg query "HKEY_LOCAL_MACHINE\\Software\\WOW6432Node\\Microsoft\\EdgeUpdate\\Clients" 2>/dev/null | grep -q "pv"; then
        echo -e "${GREEN}✓ WebView2 is installed${NC}"
    else
        echo -e "${YELLOW}⚠ WebView2 may not be installed (required for login)${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (WINEPREFIX not found)${NC}"
    ((WARNINGS++))
fi
echo ""

# Check 6: Vulkan
echo -e "${BLUE}[Check 6/10] Vulkan Support${NC}"
if command -v vulkaninfo &> /dev/null; then
    echo -e "${GREEN}✓ Vulkan is available${NC}"
else
    echo -e "${YELLOW}⚠ Vulkan tools not found (Vulkan runtime may still work)${NC}"
    ((WARNINGS++))
fi
echo ""

# Check 7: NVIDIA GPU
echo -e "${BLUE}[Check 7/10] NVIDIA GPU${NC}"
if command -v nvidia-smi &> /dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null | head -1)
    echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
    echo "  $GPU_INFO"
else
    echo -e "${YELLOW}⚠ nvidia-smi not found (GPU may still work)${NC}"
    echo "  Check: lspci | grep -i nvidia"
    ((WARNINGS++))
fi
echo ""

# Check 8: SketchUp Installation
echo -e "${BLUE}[Check 8/10] SketchUp 2026${NC}"
SKETCHUP_PATHS=(
    "$WINE_PREFIX/drive_c/Program Files/SketchUp/SketchUp 2026/SketchUp.exe"
    "$WINE_PREFIX/drive_c/Program Files (x86)/SketchUp/SketchUp 2026/SketchUp.exe"
)

FOUND=0
for path in "${SKETCHUP_PATHS[@]}"; do
    if [ -f "$path" ]; then
        echo -e "${GREEN}✓ SketchUp 2026 installed${NC}"
        echo "  Location: $path"
        FOUND=1
        break
    fi
done

if [ $FOUND -eq 0 ]; then
    echo -e "${YELLOW}⚠ SketchUp 2026 not installed${NC}"
    echo "  Run: ./scripts/04-install-sketchup.sh"
    ((WARNINGS++))
fi
echo ""

# Check 9: Scripts
echo -e "${BLUE}[Check 9/10] Helper Scripts${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS=(
    "00-master-setup.sh"
    "03-launch-sketchup.sh"
    "04-install-sketchup.sh"
)

ALL_EXECUTABLE=1
for script in "${SCRIPTS[@]}"; do
    if [ -x "$SCRIPT_DIR/$script" ]; then
        echo -e "${GREEN}✓ $script (executable)${NC}"
    elif [ -f "$SCRIPT_DIR/$script" ]; then
        echo -e "${YELLOW}⚠ $script (not executable)${NC}"
        echo "  Run: chmod +x $SCRIPT_DIR/$script"
        ALL_EXECUTABLE=0
    else
        echo -e "${RED}✗ $script (not found)${NC}"
        ((ISSUES++))
    fi
done

if [ $ALL_EXECUTABLE -eq 0 ]; then
    ((WARNINGS++))
fi
echo ""

# Check 10: Documentation
echo -e "${BLUE}[Check 10/10] Documentation${NC}"
DOC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docs" && pwd)"
DOCS=(
    "README.md"
    "NVIDIA-GPU-OFFLOADING.md"
    "TROUBLESHOOTING.md"
    "WINETRICKS-COMPONENTS.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$DOC_DIR/$doc" ]; then
        echo -e "${GREEN}✓ $doc${NC}"
    else
        echo -e "${YELLOW}⚠ $doc (not found)${NC}"
        ((WARNINGS++))
    fi
done
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Verification Summary                                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your system is ready. To launch SketchUp:"
    echo "  ./scripts/03-launch-sketchup.sh"
elif [ $ISSUES -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    if ! [ -d "$WINE_PREFIX/drive_c/Program Files/SketchUp/SketchUp 2026/SketchUp.exe" ]; then
        echo "Most common fix: Install SketchUp"
        echo "  ./scripts/04-install-sketchup.sh"
    fi
else
    echo -e "${RED}✗ $ISSUES critical issue(s) found${NC}"
    echo ""
    echo "Setup incomplete. Run:"
    echo "  ./scripts/00-master-setup.sh"
fi

echo ""
