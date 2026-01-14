#!/bin/bash
# MSI Capture Script - Runs installer while monitoring for MSI extraction

BOTTLE_PREFIX="$HOME/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026"
INSTALLER="/home/tomas/SketchUp-2026-1-189-46.exe"
CAPTURE_DIR="$HOME/SketchUp 2026/HOLYFUCKINGWINE/captured-msi"
TEMP_DIR="$BOTTLE_PREFIX/drive_c/users/tomas/Temp"

mkdir -p "$CAPTURE_DIR"
mkdir -p "$TEMP_DIR"

echo "=== MSI Capture Script ==="
echo "Monitoring: $TEMP_DIR"
echo "Capture to: $CAPTURE_DIR"
echo ""

# Background monitor using inotifywait (if available) or polling loop
capture_files() {
    while true; do
        # Look for any new MSI or large files in temp
        find "$TEMP_DIR" -type f \( -name "*.msi" -o -name "*.MSI" -o -size +100M \) 2>/dev/null | while read f; do
            fname=$(basename "$f")
            if [ ! -f "$CAPTURE_DIR/$fname" ]; then
                echo "[CAPTURE] Found: $f"
                cp -v "$f" "$CAPTURE_DIR/" 2>/dev/null
            fi
        done
        
        # Also check the Windows Temp location pattern that InstallShield uses
        find "$TEMP_DIR" -type d -name "*InstallShield*" 2>/dev/null | while read d; do
            echo "[FOUND] InstallShield directory: $d"
            cp -rv "$d" "$CAPTURE_DIR/" 2>/dev/null
        done
        
        # Also check for GUID-named temp folders
        find "$TEMP_DIR" -type d -name "{*}" 2>/dev/null | while read d; do
            dname=$(basename "$d")
            if [ ! -d "$CAPTURE_DIR/$dname" ]; then
                echo "[CAPTURE] GUID folder: $d"
                cp -rv "$d" "$CAPTURE_DIR/" 2>/dev/null
            fi
        done
        
        sleep 0.5
    done
}

# Start background monitor
capture_files &
MONITOR_PID=$!
echo "Monitor PID: $MONITOR_PID"

# Give it a moment
sleep 1

echo ""
echo "Starting installer via Bottles CLI..."
echo "Press Ctrl+C to stop monitoring after installer closes"
echo ""

# Run the installer via Bottles
flatpak run --command=bottles-cli com.usebottles.bottles run \
    -b "SketchUp2026" \
    -e "$INSTALLER" &

INSTALLER_PID=$!
echo "Installer PID: $INSTALLER_PID"

# Wait for installer to finish (or user interrupt)
wait $INSTALLER_PID 2>/dev/null

echo ""
echo "Installer exited. Waiting 5s for final capture..."
sleep 5

# Kill the monitor
kill $MONITOR_PID 2>/dev/null

echo ""
echo "=== Captured files ==="
ls -la "$CAPTURE_DIR"

