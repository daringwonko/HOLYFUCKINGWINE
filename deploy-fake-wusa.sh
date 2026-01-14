#!/bin/bash
# Deploy fake-wusa.exe for SketchUp installer
# Compiles 32-bit and 64-bit versions and places them correctly for WoW64 redirection

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=============================================="
echo -e "  Fake wusa.exe Deployment Script"
echo -e "==============================================${NC}"
echo ""

# The actual Wine prefix location (Bottles uses custom path via document portal)
# Check both possible locations
BOTTLES_PREFIX_STANDARD="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026"
BOTTLES_PREFIX_CUSTOM="$HOME/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026"

# Determine which prefix exists and has the wine structure
if [ -d "$BOTTLES_PREFIX_CUSTOM/drive_c/windows" ]; then
    BOTTLES_PREFIX="$BOTTLES_PREFIX_CUSTOM"
elif [ -d "$BOTTLES_PREFIX_STANDARD/drive_c/windows" ]; then
    BOTTLES_PREFIX="$BOTTLES_PREFIX_STANDARD"
else
    echo -e "${RED}ERROR: No valid Bottles prefix found!${NC}"
    echo "Checked:"
    echo "  - $BOTTLES_PREFIX_CUSTOM"
    echo "  - $BOTTLES_PREFIX_STANDARD"
    exit 1
fi

SYSTEM32="$BOTTLES_PREFIX/drive_c/windows/system32"
SYSWOW64="$BOTTLES_PREFIX/drive_c/windows/syswow64"

# Prefix validation already done above

echo "Bottles prefix: $BOTTLES_PREFIX"
echo ""

# Check for mingw compilers
echo "Checking for MinGW compilers..."
HAS_32BIT=false
HAS_64BIT=false

if command -v i686-w64-mingw32-gcc &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} 32-bit compiler: i686-w64-mingw32-gcc"
    HAS_32BIT=true
else
    echo -e "  ${YELLOW}✗${NC} 32-bit compiler not found"
fi

if command -v x86_64-w64-mingw32-gcc &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} 64-bit compiler: x86_64-w64-mingw32-gcc"
    HAS_64BIT=true
else
    echo -e "  ${YELLOW}✗${NC} 64-bit compiler not found"
fi

if [ "$HAS_32BIT" = false ] && [ "$HAS_64BIT" = false ]; then
    echo ""
    echo -e "${RED}ERROR: No MinGW compilers found!${NC}"
    echo "Install with: sudo dnf install mingw32-gcc mingw64-gcc"
    echo "         or: sudo apt install gcc-mingw-w64-i686 gcc-mingw-w64-x86-64"
    exit 1
fi

echo ""

# Navigate to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for fake-wusa.c
if [ ! -f "fake-wusa.c" ]; then
    echo -e "${RED}ERROR: fake-wusa.c not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Create build directory
mkdir -p build

# Compile 32-bit version (CRITICAL for 32-bit InstallShield installer)
if [ "$HAS_32BIT" = true ]; then
    echo "Compiling 32-bit wusa.exe..."
    i686-w64-mingw32-gcc fake-wusa.c -o build/wusa32.exe -mwindows
    echo -e "  ${GREEN}✓${NC} build/wusa32.exe created"
else
    echo -e "  ${YELLOW}!${NC} Skipping 32-bit (compiler not available)"
fi

# Compile 64-bit version
if [ "$HAS_64BIT" = true ]; then
    echo "Compiling 64-bit wusa.exe..."
    x86_64-w64-mingw32-gcc fake-wusa.c -o build/wusa64.exe -mwindows
    echo -e "  ${GREEN}✓${NC} build/wusa64.exe created"
else
    echo -e "  ${YELLOW}!${NC} Skipping 64-bit (compiler not available)"
fi

echo ""

# Backup existing wusa.exe files
echo "Backing up existing wusa.exe files..."

if [ -f "$SYSWOW64/wusa.exe" ]; then
    cp "$SYSWOW64/wusa.exe" "$SYSWOW64/wusa.exe.backup" 2>/dev/null || true
    echo "  Backed up SysWOW64/wusa.exe"
fi

if [ -f "$SYSTEM32/wusa.exe" ]; then
    cp "$SYSTEM32/wusa.exe" "$SYSTEM32/wusa.exe.backup" 2>/dev/null || true
    echo "  Backed up System32/wusa.exe"
fi

echo ""

# Deploy fake wusa.exe
echo "Deploying fake wusa.exe..."

# CRITICAL: 32-bit goes to SysWOW64 (what 32-bit processes see as "System32")
if [ -f "build/wusa32.exe" ]; then
    cp build/wusa32.exe "$SYSWOW64/wusa.exe"
    echo -e "  ${GREEN}✓${NC} 32-bit wusa.exe -> SysWOW64/ (for 32-bit installer)"
fi

# 64-bit goes to actual System32
if [ -f "build/wusa64.exe" ]; then
    cp build/wusa64.exe "$SYSTEM32/wusa.exe"
    echo -e "  ${GREEN}✓${NC} 64-bit wusa.exe -> System32/"
fi

echo ""
echo -e "${GREEN}=============================================="
echo -e "  Deployment Complete!"
echo -e "==============================================${NC}"
echo ""
echo "The fake wusa.exe will now return SUCCESS (0) for any KB update check."
echo "This should allow the SketchUp installer to skip the KB2999226 prerequisite."
echo ""
echo "Next step: Run the installer in Bottles"
echo ""
echo "To restore original wusa.exe:"
echo "  mv '$SYSWOW64/wusa.exe.backup' '$SYSWOW64/wusa.exe'"
echo "  mv '$SYSTEM32/wusa.exe.backup' '$SYSTEM32/wusa.exe'"
