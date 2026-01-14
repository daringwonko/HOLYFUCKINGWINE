#!/bin/bash
# Aggressive MSI Capture Script
# Captures any new files in Wine temp directories with 100ms polling

set -e

BOTTLE_PREFIX="$HOME/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026"
INSTALLER="/home/tomas/SketchUp-2026-1-189-46.exe"
CAPTURE_DIR="$HOME/SketchUp 2026/HOLYFUCKINGWINE/captured-msi"
BOTTLES_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1"

# Multiple temp locations to monitor (Bottles uses steamuser, but also check tomas)
TEMP_DIRS=(
    "$BOTTLE_PREFIX/drive_c/users/steamuser/Temp"
    "$BOTTLE_PREFIX/drive_c/users/tomas/Temp"
    "$BOTTLE_PREFIX/drive_c/users/Public/Temp"
    "$BOTTLE_PREFIX/drive_c/windows/Temp"
    "$BOTTLE_PREFIX/drive_c/ProgramData"
)

echo "=============================================="
echo "  Aggressive MSI Capture Script"
echo "=============================================="
echo ""
echo "Capture Dir: $CAPTURE_DIR"
echo "Installer:   $INSTALLER"
echo ""

# Create directories
mkdir -p "$CAPTURE_DIR"
for dir in "${TEMP_DIRS[@]}"; do
    mkdir -p "$dir" 2>/dev/null || true
done

# Clear any previous captures
rm -rf "$CAPTURE_DIR"/* 2>/dev/null || true

# Background aggressive monitor with very fast polling
aggressive_capture() {
    local seen_file="$CAPTURE_DIR/.seen_files"
    touch "$seen_file"
    
    while true; do
        for dir in "${TEMP_DIRS[@]}"; do
            if [ -d "$dir" ]; then
                # Find all files created in last 5 minutes
                find "$dir" -type f -mmin -5 2>/dev/null | while read f; do
                    fname=$(basename "$f")
                    # Skip small files and known system files
                    fsize=$(stat -c%s "$f" 2>/dev/null || echo "0")
                    
                    # Only capture files > 1MB or MSI files
                    if [[ "$fname" == *.msi ]] || [[ "$fname" == *.MSI ]] || [[ "$fsize" -gt 1048576 ]]; then
                        if ! grep -qF "$f" "$seen_file" 2>/dev/null; then
                            echo "$f" >> "$seen_file"
                            echo "[$(date +%H:%M:%S.%N)] CAPTURE: $f ($fsize bytes)"
                            cp -p "$f" "$CAPTURE_DIR/" 2>/dev/null && echo "  -> Saved to $CAPTURE_DIR/$fname"
                        fi
                    fi
                done
                
                # Also capture entire directories with InstallShield or GUID names
                find "$dir" -type d \( -name "*InstallShield*" -o -name "{*}" \) -mmin -5 2>/dev/null | while read d; do
                    dname=$(basename "$d")
                    if [ ! -d "$CAPTURE_DIR/$dname" ]; then
                        echo "[$(date +%H:%M:%S.%N)] CAPTURE DIR: $d"
                        cp -rp "$d" "$CAPTURE_DIR/" 2>/dev/null && echo "  -> Saved directory to $CAPTURE_DIR/$dname"
                    fi
                done
            fi
        done
        
        # Super fast 100ms poll
        sleep 0.1
    done
}

echo "Starting aggressive file monitor (100ms polling)..."
aggressive_capture &
MONITOR_PID=$!
echo "Monitor PID: $MONITOR_PID"

sleep 1

echo ""
echo "Launching installer..."
echo "=============================================="
echo "IMPORTANT: Let the installer run as far as it can!"
echo "Even if it shows errors, wait for files to be extracted."
echo "Press Ctrl+C ONLY after the installer has fully closed."
echo "=============================================="
echo ""

# Run the installer
export WINEPREFIX="$BOTTLE_PREFIX"
export WINEDEBUG=-all

# Use Bottles runner directly
"$BOTTLES_RUNNER/bin/wine" "$INSTALLER" 2>&1 &
INSTALLER_PID=$!

echo "Installer PID: $INSTALLER_PID"
echo ""
echo "Capturing files... (watch for [CAPTURE] messages)"
echo ""

# Wait for installer to exit
wait $INSTALLER_PID 2>/dev/null || true

echo ""
echo "Installer exited. Capturing remaining files for 10 seconds..."
sleep 10

# Kill the monitor
kill $MONITOR_PID 2>/dev/null || true

echo ""
echo "=============================================="
echo "  Capture Complete"
echo "=============================================="
echo ""
echo "Captured files:"
ls -la "$CAPTURE_DIR" 2>/dev/null | head -30

# Check for MSI specifically
echo ""
echo "MSI files found:"
find "$CAPTURE_DIR" -name "*.msi" -o -name "*.MSI" 2>/dev/null
