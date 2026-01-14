#!/bin/bash
# Script to capture MSI files extracted by SketchUp installer
# Run this BEFORE starting the installer, then start the installer in Bottles

BOTTLE_PATH="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026/drive_c"
OUTPUT_DIR="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/captured-msi"

mkdir -p "$OUTPUT_DIR"

echo "=== MSI Capture Script ==="
echo "Bottle path: $BOTTLE_PATH"
echo "Output dir: $OUTPUT_DIR"
echo ""
echo "Starting file monitor... Press Ctrl+C to stop"
echo "NOW START THE SKETCHUP INSTALLER IN BOTTLES"
echo ""

# Record time before running
touch /tmp/.msi-capture-start
START_TIME=$(date +%s)

# Function to check and copy MSI files
copy_msi() {
    local path="$1"
    local label="$2"
    
    if [ -d "$path" ]; then
        MSI_FILES=$(find "$path" -name "*.msi" -o -name "*.MSI" 2>/dev/null)
        if [ -n "$MSI_FILES" ]; then
            echo ""
            echo ">>> FOUND MSI IN $label <<<"
            for msi in $MSI_FILES; do
                if [ ! -f "$OUTPUT_DIR/$(basename "$msi")" ]; then
                    echo "Copying: $msi"
                    cp -v "$msi" "$OUTPUT_DIR/" 2>/dev/null
                fi
            done
        fi
    fi
}

# Monitor loop
COUNTER=0
while true; do
    # Check various paths
    copy_msi "$BOTTLE_PATH" "BOTTLE DRIVE_C"
    copy_msi "$BOTTLE_PATH/windows/Temp" "WINDOWS TEMP"
    copy_msi "$BOTTLE_PATH/users/steamuser/Temp" "STEAMUSER TEMP"
    copy_msi "$BOTTLE_PATH/users/steamuser/Local Settings/Temp" "STEAMUSER LOCAL TEMP"
    copy_msi "$BOTTLE_PATH/users/Public/Temp" "PUBLIC TEMP"
    copy_msi "/tmp" "LINUX /tmp"
    
    # Also check for any ~IS*.tmp folders in /tmp (InstallShield uses these)
    for isdir in /tmp/~IS*.tmp /tmp/*InstallShield* /tmp/*Setup*; do
        copy_msi "$isdir" "INSTALLSHIELD TEMP"
    done
    
    # Status indicator every 10 seconds
    COUNTER=$((COUNTER + 1))
    if [ $((COUNTER % 10)) -eq 0 ]; then
        echo -n "."
    fi
    
    # Check if any files were captured
    CAPTURED=$(ls -1 "$OUTPUT_DIR"/*.msi 2>/dev/null | wc -l)
    if [ "$CAPTURED" -gt 0 ]; then
        echo ""
        echo "=== CAPTURED $CAPTURED MSI FILE(S)! ==="
        ls -la "$OUTPUT_DIR"
        echo ""
        echo "Press Ctrl+C to stop monitoring, or wait for more files..."
    fi
    
    sleep 1
done
