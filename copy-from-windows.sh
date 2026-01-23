#!/bin/bash
##############################################################################
# Copy SketchUp 2026 from Windows Extraction to Wine/Bottles Prefix
#
# Usage:
#   ./copy-from-windows.sh <extraction-dir> [bottle-prefix]
#
# Arguments:
#   extraction-dir  - Directory containing extracted Windows files
#   bottle-prefix   - (Optional) Target Wine/Bottles prefix
#                     Default: Auto-detect Bottles SketchUp prefix
#
# Example:
#   ./copy-from-windows.sh ~/vm-shared/sketchup-extraction
#   ./copy-from-windows.sh ~/vm-shared/sketchup-extraction ~/.sketchup2026
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
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

# Header
print_header "SketchUp 2026 Windows Extraction Importer"

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <extraction-dir> [bottle-prefix]"
    echo ""
    echo "Arguments:"
    echo "  extraction-dir  Directory containing extracted Windows SketchUp files"
    echo "  bottle-prefix   (Optional) Target Wine/Bottles prefix"
    echo ""
    echo "The extraction directory should contain:"
    echo "  Program Files/SketchUp/SketchUp 2026/"
    echo "  AppData/Roaming/SketchUp/"
    echo "  AppData/Local/SketchUp/"
    echo "  ProgramData/SketchUp/"
    echo ""
    echo "Examples:"
    echo "  $0 ~/vm-shared/sketchup-extraction"
    echo "  $0 ~/vm-shared/sketchup-extraction ~/.sketchup2026"
    exit 1
fi

EXTRACTION_DIR="$1"

# Validate extraction directory
if [ ! -d "$EXTRACTION_DIR" ]; then
    print_error "Extraction directory not found: $EXTRACTION_DIR"
    exit 1
fi

# Check for required files in extraction
if [ ! -d "$EXTRACTION_DIR/Program Files/SketchUp/SketchUp 2026" ]; then
    print_error "Invalid extraction directory structure"
    echo "Expected: $EXTRACTION_DIR/Program Files/SketchUp/SketchUp 2026/"
    echo ""
    echo "Please ensure you extracted files following the Windows VM guide."
    exit 1
fi

print_success "Extraction directory validated: $EXTRACTION_DIR"

# Determine bottle prefix
if [ $# -ge 2 ]; then
    BOTTLE_PREFIX="$2"
else
    # Auto-detect Bottles prefix
    BOTTLES_BASE="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles"

    if [ -d "$BOTTLES_BASE" ]; then
        # Look for SketchUp-related bottles
        FOUND_BOTTLE=""
        for bottle in "$BOTTLES_BASE"/*; do
            if [ -d "$bottle" ]; then
                bottle_name=$(basename "$bottle")
                if [[ "$bottle_name" == *[Ss]ketch[Uu]p* ]] || [[ "$bottle_name" == *SKETCHUP* ]]; then
                    FOUND_BOTTLE="$bottle"
                    break
                fi
            fi
        done

        if [ -n "$FOUND_BOTTLE" ]; then
            BOTTLE_PREFIX="$FOUND_BOTTLE"
            print_success "Auto-detected Bottles prefix: $BOTTLE_PREFIX"
        else
            # List available bottles
            echo ""
            echo "Available Bottles prefixes:"
            ls -1 "$BOTTLES_BASE" 2>/dev/null | while read bottle; do
                echo "  - $BOTTLES_BASE/$bottle"
            done
            echo ""
            read -p "Enter target bottle prefix path: " BOTTLE_PREFIX
        fi
    else
        # Fall back to standard Wine prefix
        BOTTLE_PREFIX="$HOME/.sketchup2026"
        print_warning "Bottles not found, using standard prefix: $BOTTLE_PREFIX"
    fi
fi

# Validate bottle prefix
if [ ! -d "$BOTTLE_PREFIX" ]; then
    print_error "Bottle prefix not found: $BOTTLE_PREFIX"
    echo "Please create the bottle first using Bottles or run 00-master-setup.sh"
    exit 1
fi

if [ ! -d "$BOTTLE_PREFIX/drive_c" ]; then
    print_error "Invalid Wine prefix (no drive_c): $BOTTLE_PREFIX"
    exit 1
fi

print_success "Target prefix validated: $BOTTLE_PREFIX"
echo ""

# Determine Wine username in prefix
WINE_USER=""
for user_dir in "$BOTTLE_PREFIX/drive_c/users/"*/; do
    user_name=$(basename "$user_dir")
    if [[ "$user_name" != "Public" ]] && [[ "$user_name" != "steamuser" ]]; then
        WINE_USER="$user_name"
        break
    fi
done

if [ -z "$WINE_USER" ]; then
    # Fall back to steamuser if no other user found
    if [ -d "$BOTTLE_PREFIX/drive_c/users/steamuser" ]; then
        WINE_USER="steamuser"
    else
        print_error "Could not determine Wine user in prefix"
        exit 1
    fi
fi

print_success "Wine user detected: $WINE_USER"
echo ""

# Show what will be copied
echo -e "${BLUE}Files to copy:${NC}"
echo ""

PROGRAM_FILES_SRC="$EXTRACTION_DIR/Program Files/SketchUp/SketchUp 2026"
APPDATA_ROAMING_SRC="$EXTRACTION_DIR/AppData/Roaming/SketchUp"
APPDATA_LOCAL_SRC="$EXTRACTION_DIR/AppData/Local/SketchUp"
PROGRAMDATA_SRC="$EXTRACTION_DIR/ProgramData/SketchUp"

PROGRAM_FILES_DST="$BOTTLE_PREFIX/drive_c/Program Files/SketchUp"
APPDATA_ROAMING_DST="$BOTTLE_PREFIX/drive_c/users/$WINE_USER/AppData/Roaming/SketchUp"
APPDATA_LOCAL_DST="$BOTTLE_PREFIX/drive_c/users/$WINE_USER/AppData/Local/SketchUp"
PROGRAMDATA_DST="$BOTTLE_PREFIX/drive_c/ProgramData/SketchUp"

echo "Source → Destination:"
echo ""
[ -d "$PROGRAM_FILES_SRC" ] && echo "  Program Files/SketchUp/SketchUp 2026/"
[ -d "$PROGRAM_FILES_SRC" ] && echo "    → $PROGRAM_FILES_DST/"
echo ""
[ -d "$APPDATA_ROAMING_SRC" ] && echo "  AppData/Roaming/SketchUp/"
[ -d "$APPDATA_ROAMING_SRC" ] && echo "    → $APPDATA_ROAMING_DST/"
echo ""
[ -d "$APPDATA_LOCAL_SRC" ] && echo "  AppData/Local/SketchUp/"
[ -d "$APPDATA_LOCAL_SRC" ] && echo "    → $APPDATA_LOCAL_DST/"
echo ""
[ -d "$PROGRAMDATA_SRC" ] && echo "  ProgramData/SketchUp/"
[ -d "$PROGRAMDATA_SRC" ] && echo "    → $PROGRAMDATA_DST/"
echo ""

# Calculate total size
TOTAL_SIZE=$(du -sh "$EXTRACTION_DIR" 2>/dev/null | cut -f1)
echo "Total extraction size: $TOTAL_SIZE"
echo ""

# Confirm
read -p "Proceed with copy? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
print_header "Copying Files..."

# Create destination directories
mkdir -p "$PROGRAM_FILES_DST"
mkdir -p "$APPDATA_ROAMING_DST"
mkdir -p "$APPDATA_LOCAL_DST"
mkdir -p "$PROGRAMDATA_DST"

# Copy Program Files
if [ -d "$PROGRAM_FILES_SRC" ]; then
    echo "Copying Program Files..."
    cp -r "$PROGRAM_FILES_SRC" "$PROGRAM_FILES_DST/"
    print_success "Program Files copied"
fi

# Copy AppData Roaming
if [ -d "$APPDATA_ROAMING_SRC" ]; then
    echo "Copying AppData/Roaming..."
    cp -r "$APPDATA_ROAMING_SRC"/* "$APPDATA_ROAMING_DST/" 2>/dev/null || true
    print_success "AppData/Roaming copied"
fi

# Copy AppData Local
if [ -d "$APPDATA_LOCAL_SRC" ]; then
    echo "Copying AppData/Local..."
    cp -r "$APPDATA_LOCAL_SRC"/* "$APPDATA_LOCAL_DST/" 2>/dev/null || true
    print_success "AppData/Local copied"
fi

# Copy ProgramData
if [ -d "$PROGRAMDATA_SRC" ]; then
    echo "Copying ProgramData..."
    cp -r "$PROGRAMDATA_SRC"/* "$PROGRAMDATA_DST/" 2>/dev/null || true
    print_success "ProgramData copied"
fi

echo ""

# Import registry files if present
if [ -f "$EXTRACTION_DIR/sketchup-hklm.reg" ] || [ -f "$EXTRACTION_DIR/sketchup-hkcu.reg" ]; then
    print_header "Importing Registry Keys..."

    export WINEPREFIX="$BOTTLE_PREFIX"

    # Check if we're using Bottles runner or system Wine
    if [ -d "$HOME/.var/app/com.usebottles.bottles/data/bottles/runners" ]; then
        # Find a runner
        RUNNER=$(ls -1 "$HOME/.var/app/com.usebottles.bottles/data/bottles/runners" 2>/dev/null | head -1)
        if [ -n "$RUNNER" ]; then
            WINE_CMD="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/$RUNNER/bin/wine"
        else
            WINE_CMD="wine"
        fi
    else
        WINE_CMD="wine"
    fi

    # Convert and import registry files
    for regfile in "$EXTRACTION_DIR"/*.reg; do
        if [ -f "$regfile" ]; then
            regname=$(basename "$regfile")
            echo "Processing: $regname"

            # Convert from UTF-16 to UTF-8 if needed
            if file "$regfile" | grep -q "UTF-16"; then
                echo "  Converting from UTF-16..."
                iconv -f UTF-16LE -t UTF-8 "$regfile" > "/tmp/$regname.utf8" 2>/dev/null || true
                if [ -f "/tmp/$regname.utf8" ]; then
                    $WINE_CMD regedit "/tmp/$regname.utf8" 2>/dev/null || print_warning "Registry import may have failed"
                    rm "/tmp/$regname.utf8"
                fi
            else
                $WINE_CMD regedit "$regfile" 2>/dev/null || print_warning "Registry import may have failed"
            fi

            print_success "Imported: $regname"
        fi
    done
fi

echo ""

# Verify installation
print_header "Verification"

SKETCHUP_EXE="$PROGRAM_FILES_DST/SketchUp 2026/SketchUp.exe"
if [ -f "$SKETCHUP_EXE" ]; then
    print_success "SketchUp.exe found!"
    echo "  Path: $SKETCHUP_EXE"
    echo "  Size: $(du -h "$SKETCHUP_EXE" | cut -f1)"
else
    print_warning "SketchUp.exe not found at expected location"
    echo "  Expected: $SKETCHUP_EXE"
    echo ""
    echo "Searching for SketchUp.exe..."
    find "$PROGRAM_FILES_DST" -name "SketchUp.exe" 2>/dev/null | head -5
fi

# Check for LayOut
LAYOUT_EXE="$PROGRAM_FILES_DST/SketchUp 2026/LayOut/LayOut.exe"
if [ -f "$LAYOUT_EXE" ]; then
    print_success "LayOut.exe found"
elif [ -f "$PROGRAM_FILES_DST/SketchUp 2026/LayOut.exe" ]; then
    print_success "LayOut.exe found (alternate location)"
fi

echo ""
print_header "Import Complete!"

echo "SketchUp 2026 files have been copied to your Wine prefix."
echo ""
echo "To launch SketchUp:"
echo ""

# Provide appropriate launch command
if [[ "$BOTTLE_PREFIX" == *".var/app/com.usebottles.bottles"* ]]; then
    echo "  Option 1: Use Bottles GUI"
    echo "    - Open Bottles"
    echo "    - Select your SketchUp bottle"
    echo "    - Run SketchUp.exe"
    echo ""
    echo "  Option 2: Command line"
    echo "    export WINEPREFIX=\"$BOTTLE_PREFIX\""
    if [ -n "$RUNNER" ]; then
        echo "    $WINE_CMD \"$SKETCHUP_EXE\""
    else
        echo "    wine \"$SKETCHUP_EXE\""
    fi
else
    echo "  ./sketchup-wine-setup/scripts/03-launch-sketchup.sh"
    echo ""
    echo "  Or manually:"
    echo "    export WINEPREFIX=\"$BOTTLE_PREFIX\""
    echo "    export __NV_PRIME_RENDER_OFFLOAD=1"
    echo "    export __GLX_VENDOR_LIBRARY_NAME=nvidia"
    echo "    wine \"$SKETCHUP_EXE\""
fi

echo ""
echo "If Trimble login doesn't work, ensure WebView2 is installed in the prefix."
echo ""
