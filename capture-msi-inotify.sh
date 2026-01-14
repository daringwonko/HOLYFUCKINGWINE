#!/bin/bash
# Real-time MSI Capture using inotifywait
# Captures files the INSTANT they're created

set -e

BOTTLE_PREFIX="$HOME/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026"
INSTALLER="/home/tomas/SketchUp-2026-1-189-46.exe"
CAPTURE_DIR="$HOME/SketchUp 2026/HOLYFUCKINGWINE/captured-msi"
BOTTLES_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1"

# Multiple temp locations to monitor
TEMP_DIRS=(
    "$BOTTLE_PREFIX/drive_c/users/steamuser/Temp"
    "$BOTTLE_PREFIX/drive_c/users/tomas/Temp"
    "$BOTTLE_PREFIX/drive_c/windows/Temp"
)

echo "=============================================="
echo "  Real-Time MSI Capture (inotifywait)"
echo "=============================================="
echo ""

# Create directories
mkdir -p "$CAPTURE_DIR"
for dir in "${TEMP_DIRS[@]}"; do
    mkdir -p "$dir" 2>/dev/null || true
done

# Clear captures
rm -rf "$CAPTURE_DIR"/* 2>/dev/null || true

# Start inotifywait monitors for each temp directory
start_inotify_monitor() {
    local watch_dir="$1"
    local name="$2"
    
    inotifywait -m -r -e create -e moved_to --format '%w%f' "$watch_dir" 2>/dev/null | while read filepath; do
        fname=$(basename "$filepath")
        
        # Skip if it's a directory marker
        [ -f "$filepath" ] || continue
        
        # Get file size
        fsize=$(stat -c%s "$filepath" 2>/dev/null || echo "0")
        
        echo "[$name] NEW FILE: $filepath ($fsize bytes)"
        
        # Capture MSI files or large files immediately
        if [[ "$fname" == *.msi ]] || [[ "$fname" == *.MSI ]] || [[ "$fsize" -gt 5242880 ]]; then
            echo "[$name] >>> CAPTURING: $fname"
            cp -p "$filepath" "$CAPTURE_DIR/" 2>/dev/null && echo "[$name] >>> SAVED!"
        fi
        
        # Also capture if path contains "SketchUp" or "InstallShield"
        if [[ "$filepath" == *SketchUp* ]] || [[ "$filepath" == *InstallShield* ]]; then
            echo "[$name] >>> CAPTURING (keyword match): $fname"
            cp -p "$filepath" "$CAPTURE_DIR/" 2>/dev/null
        fi
    done &
}

echo "Starting inotify monitors..."

for i in "${!TEMP_DIRS[@]}"; do
    dir="${TEMP_DIRS[$i]}"
    if [ -d "$dir" ]; then
        start_inotify_monitor "$dir" "TEMP$i"
        echo "  - Monitoring: $dir"
    fi
done

MONITOR_PIDS=$(jobs -p)
echo ""
echo "Monitor PIDs: $MONITOR_PIDS"
echo ""

sleep 1

echo "=============================================="
echo "  Launching Installer..."
echo "=============================================="
echo ""
echo "Let it run! Watch for >>> CAPTURING messages."
echo "Press Ctrl+C after installer closes."
echo ""

# Run the installer
export WINEPREFIX="$BOTTLE_PREFIX"
export WINEDEBUG=-all

"$BOTTLES_RUNNER/bin/wine" "$INSTALLER" 2>&1 &
INSTALLER_PID=$!

echo "Installer PID: $INSTALLER_PID"
echo ""

# Wait for installer
wait $INSTALLER_PID 2>/dev/null || true

echo ""
echo "Installer exited. Waiting 15 seconds for final captures..."
sleep 15

# Kill all background jobs
kill $(jobs -p) 2>/dev/null || true

echo ""
echo "=============================================="
echo "  Capture Results"
echo "=============================================="
echo ""
echo "Files in capture directory:"
ls -lah "$CAPTURE_DIR" 2>/dev/null

echo ""
echo "MSI files specifically:"
find "$CAPTURE_DIR" -name "*.msi" -o -name "*.MSI" 2>/dev/null | while read f; do
    echo "  - $(basename "$f") ($(stat -c%s "$f" 2>/dev/null || echo "?") bytes)"
done

echo ""
echo "Total captured:"
du -sh "$CAPTURE_DIR" 2>/dev/null
