#!/bin/bash
# Simple MSI Watcher for Manual "Snatch and Grab" Approach
# Run this in one terminal while running the installer in Bottles

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=============================================="
echo -e "  MSI Watcher - Manual Snatch and Grab"
echo -e "==============================================${NC}"
echo ""

# The actual Wine prefix location
# Bottles uses custom path via document portal to our project directory
BOTTLES_PREFIX_CUSTOM="$HOME/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026"
BOTTLES_PREFIX_STANDARD="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026"

# Use the custom path if it exists with wine structure
if [ -d "$BOTTLES_PREFIX_CUSTOM/drive_c" ]; then
    BOTTLES_PREFIX="$BOTTLES_PREFIX_CUSTOM"
elif [ -d "$BOTTLES_PREFIX_STANDARD/drive_c" ]; then
    BOTTLES_PREFIX="$BOTTLES_PREFIX_STANDARD"
else
    echo "ERROR: No valid Bottles prefix found!"
    exit 1
fi

echo "Using prefix: $BOTTLES_PREFIX"

# The temp directories to watch
TEMP_DIRS=(
    "$BOTTLES_PREFIX/drive_c/users/$(whoami)/Temp"
    "$BOTTLES_PREFIX/drive_c/users/steamuser/Temp"
    "$BOTTLES_PREFIX/drive_c/windows/Temp"
    "$BOTTLES_PREFIX/drive_c/users/Public/Temp"
)

# Capture directory
CAPTURE_DIR="$HOME/SketchUp 2026/HOLYFUCKINGWINE/captured-msi"
mkdir -p "$CAPTURE_DIR"

echo "Watching these directories for MSI files:"
for dir in "${TEMP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "  ${GREEN}✓${NC} $dir"
    else
        echo -e "  ${YELLOW}?${NC} $dir (will create)"
        mkdir -p "$dir" 2>/dev/null || true
    fi
done

echo ""
echo "Capture destination: $CAPTURE_DIR"
echo ""
echo -e "${YELLOW}INSTRUCTIONS:${NC}"
echo "1. Keep this terminal visible"
echo "2. In Bottles, run the SketchUp installer"
echo "3. When you see MSI files appear below, press Ctrl+C to stop"
echo "4. Check $CAPTURE_DIR for captured files"
echo ""
echo -e "${GREEN}Watching for MSI files (100ms polling)...${NC}"
echo "Press Ctrl+C to stop."
echo ""
echo "=============================================="

# Track seen files to avoid duplicates
SEEN_FILES=$(mktemp)
trap "rm -f $SEEN_FILES" EXIT

# Polling loop
while true; do
    for dir in "${TEMP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            # Find MSI files
            find "$dir" -name "*.msi" -o -name "*.MSI" 2>/dev/null | while read msi; do
                if ! grep -qF "$msi" "$SEEN_FILES" 2>/dev/null; then
                    echo "$msi" >> "$SEEN_FILES"
                    BASENAME=$(basename "$msi")
                    SIZE=$(stat -c%s "$msi" 2>/dev/null || echo "?")
                    
                    echo ""
                    echo -e "${RED}!!!! MSI FOUND !!!!${NC}"
                    echo "  File: $msi"
                    echo "  Size: $SIZE bytes"
                    echo ""
                    
                    # Auto-capture
                    cp -p "$msi" "$CAPTURE_DIR/" 2>/dev/null && \
                        echo -e "  ${GREEN}✓ CAPTURED to $CAPTURE_DIR/$BASENAME${NC}"
                    
                    echo ""
                fi
            done
            
            # Also look for large files (>10MB) that might be MSI without extension
            find "$dir" -type f -size +10M -mmin -2 2>/dev/null | while read bigfile; do
                if ! grep -qF "$bigfile" "$SEEN_FILES" 2>/dev/null; then
                    echo "$bigfile" >> "$SEEN_FILES"
                    BASENAME=$(basename "$bigfile")
                    SIZE=$(stat -c%s "$bigfile" 2>/dev/null || echo "?")
                    
                    # Check if it's actually an MSI (magic bytes: D0 CF 11 E0)
                    MAGIC=$(xxd -l 4 "$bigfile" 2>/dev/null | head -1)
                    if echo "$MAGIC" | grep -q "d0cf 11e0"; then
                        echo ""
                        echo -e "${RED}!!!! LARGE MSI-LIKE FILE FOUND !!!!${NC}"
                        echo "  File: $bigfile"
                        echo "  Size: $SIZE bytes"
                        echo ""
                        
                        cp -p "$bigfile" "$CAPTURE_DIR/${BASENAME}.msi" 2>/dev/null && \
                            echo -e "  ${GREEN}✓ CAPTURED as ${BASENAME}.msi${NC}"
                        echo ""
                    else
                        echo "[$(date +%H:%M:%S)] Large file: $bigfile ($SIZE bytes)"
                    fi
                fi
            done
            
            # Look for InstallShield directories
            find "$dir" -maxdepth 2 -type d \( -name "*InstallShield*" -o -name "{*}" \) -mmin -5 2>/dev/null | while read isdir; do
                if ! grep -qF "$isdir" "$SEEN_FILES" 2>/dev/null; then
                    echo "$isdir" >> "$SEEN_FILES"
                    echo "[$(date +%H:%M:%S)] InstallShield dir: $isdir"
                    
                    # Check for MSI inside
                    find "$isdir" -name "*.msi" 2>/dev/null | while read innermsi; do
                        BASENAME=$(basename "$innermsi")
                        cp -p "$innermsi" "$CAPTURE_DIR/" && \
                            echo -e "  ${GREEN}✓ CAPTURED $BASENAME${NC}"
                    done
                fi
            done
        fi
    done
    
    sleep 0.1
done
