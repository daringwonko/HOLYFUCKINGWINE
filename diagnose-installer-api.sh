#!/bin/bash
##############################################################################
# SketchUp 2026 Wine API Diagnostic Script
# Captures detailed Win32 API calls to identify exact failure point
##############################################################################

set -e

# Configuration
export WINEPREFIX="$HOME/.sketchup2026"
export WINEARCH=win64
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

INSTALLER="$HOME/SketchUp-2026-1-189-46.exe"
LOG_DIR="./wine-diagnose-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

echo "============================================================"
echo "SketchUp 2026 Wine API Diagnostic"
echo "============================================================"
echo "Log directory: $LOG_DIR"
echo ""

# Validate setup
if [ ! -f "$INSTALLER" ]; then
    echo "ERROR: Installer not found at $INSTALLER"
    exit 1
fi

echo "Phase 1: Environment Summary"
echo "------------------------------------------------------------"
echo "WINEPREFIX: $WINEPREFIX"
echo "Wine version: $(wine --version)"
echo "Installer: $(file -b "$INSTALLER")"
echo ""

# Capture registry state
echo "Phase 2: Capturing Registry State..."
echo "------------------------------------------------------------"
WINEPREFIX="$WINEPREFIX" wine reg query "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" > "$LOG_DIR/registry-windows-version.txt" 2>&1 || true
WINEPREFIX="$WINEPREFIX" wine reg query "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment" > "$LOG_DIR/registry-environment.txt" 2>&1 || true
echo "  Saved to: $LOG_DIR/registry-*.txt"

# Capture environment variables
echo ""
echo "Phase 3: Wine Environment Variables..."
echo "------------------------------------------------------------"
WINEPREFIX="$WINEPREFIX" wine cmd /c set > "$LOG_DIR/wine-env-vars.txt" 2>&1 || true
echo "  Saved to: $LOG_DIR/wine-env-vars.txt"

# Key checks
echo ""
echo "Phase 4: Key System Checks..."
echo "------------------------------------------------------------"

echo "  PROCESSOR_ARCHITECTURE: $(WINEPREFIX="$WINEPREFIX" wine cmd /c 'echo %PROCESSOR_ARCHITECTURE%' 2>/dev/null | tr -d '\r')"
echo "  ProgramFiles: $(WINEPREFIX="$WINEPREFIX" wine cmd /c 'echo %ProgramFiles%' 2>/dev/null | tr -d '\r')"
echo "  ProgramW6432: $(WINEPREFIX="$WINEPREFIX" wine cmd /c 'echo %ProgramW6432%' 2>/dev/null | tr -d '\r')"

# Test IsWow64Process via a test program
echo ""
echo "Phase 5: Testing WoW64 Detection APIs..."
echo "------------------------------------------------------------"
cat > "$LOG_DIR/test_wow64.c" << 'TESTCODE'
#include <windows.h>
#include <stdio.h>

typedef BOOL (WINAPI *LPFN_ISWOW64PROCESS)(HANDLE, PBOOL);
typedef BOOL (WINAPI *LPFN_ISWOW64PROCESS2)(HANDLE, USHORT*, USHORT*);

int main() {
    SYSTEM_INFO si;
    BOOL isWow64 = FALSE;
    LPFN_ISWOW64PROCESS fnIsWow64Process;
    LPFN_ISWOW64PROCESS2 fnIsWow64Process2;
    
    printf("=== WoW64 Detection Test ===\n\n");
    
    // Method 1: GetNativeSystemInfo
    GetNativeSystemInfo(&si);
    printf("GetNativeSystemInfo().wProcessorArchitecture = %d\n", si.wProcessorArchitecture);
    printf("  (0=x86, 6=IA64, 9=AMD64, 12=ARM64)\n");
    if (si.wProcessorArchitecture == 9) {
        printf("  Result: 64-bit AMD64 detected\n\n");
    } else if (si.wProcessorArchitecture == 0) {
        printf("  Result: 32-bit x86 detected (PROBLEM!)\n\n");
    }
    
    // Method 2: IsWow64Process
    fnIsWow64Process = (LPFN_ISWOW64PROCESS)GetProcAddress(
        GetModuleHandle("kernel32"), "IsWow64Process");
    
    if (fnIsWow64Process) {
        if (fnIsWow64Process(GetCurrentProcess(), &isWow64)) {
            printf("IsWow64Process() = %s\n", isWow64 ? "TRUE" : "FALSE");
            if (isWow64) {
                printf("  Result: Running as 32-bit on 64-bit OS (correct for WoW64)\n\n");
            } else {
                printf("  Result: NOT running under WoW64 (PROBLEM!)\n\n");
            }
        } else {
            printf("IsWow64Process() FAILED: error %lu\n\n", GetLastError());
        }
    } else {
        printf("IsWow64Process() not available\n\n");
    }
    
    // Method 3: IsWow64Process2 (Windows 10+)
    fnIsWow64Process2 = (LPFN_ISWOW64PROCESS2)GetProcAddress(
        GetModuleHandle("kernel32"), "IsWow64Process2");
    
    if (fnIsWow64Process2) {
        USHORT processMachine = 0, nativeMachine = 0;
        if (fnIsWow64Process2(GetCurrentProcess(), &processMachine, &nativeMachine)) {
            printf("IsWow64Process2():\n");
            printf("  processMachine = 0x%04X\n", processMachine);
            printf("  nativeMachine = 0x%04X\n", nativeMachine);
            printf("  (0x014c=i386, 0x8664=AMD64, 0xAA64=ARM64)\n");
        } else {
            printf("IsWow64Process2() FAILED: error %lu\n", GetLastError());
        }
    } else {
        printf("IsWow64Process2() not available (Wine may not implement this)\n");
    }
    
    printf("\n=== Environment Variables ===\n");
    printf("PROCESSOR_ARCHITECTURE = %s\n", getenv("PROCESSOR_ARCHITECTURE") ? getenv("PROCESSOR_ARCHITECTURE") : "(not set)");
    printf("PROCESSOR_ARCHITEW6432 = %s\n", getenv("PROCESSOR_ARCHITEW6432") ? getenv("PROCESSOR_ARCHITEW6432") : "(not set)");
    printf("ProgramW6432 = %s\n", getenv("ProgramW6432") ? getenv("ProgramW6432") : "(not set)");
    
    return 0;
}
TESTCODE

echo "  Compiling test program..."
if command -v i686-w64-mingw32-gcc &>/dev/null; then
    i686-w64-mingw32-gcc -o "$LOG_DIR/test_wow64.exe" "$LOG_DIR/test_wow64.c" 2>/dev/null
    echo "  Running test..."
    WINEPREFIX="$WINEPREFIX" wine "$LOG_DIR/test_wow64.exe" 2>&1 | tee "$LOG_DIR/wow64-test-results.txt"
else
    echo "  SKIP: mingw32-gcc not installed"
    echo "  To install: sudo dnf install mingw32-gcc"
    echo ""
    echo "  Alternative: Running PowerShell WoW64 check..."
    WINEPREFIX="$WINEPREFIX" wine cmd /c "echo %PROCESSOR_ARCHITECTURE% %PROCESSOR_ARCHITEW6432%" 2>/dev/null | tee "$LOG_DIR/wow64-env-check.txt"
fi

# Run installer with RELAY tracing (captures all API calls)
echo ""
echo "Phase 6: Running Installer with API Tracing..."
echo "------------------------------------------------------------"
echo "This will capture ALL Win32 API calls related to WoW64 and architecture detection."
echo "The installer GUI will open - please click through the error dialogs."
echo "Press Ctrl+C after you see the error to stop logging."
echo ""

# Trace specific APIs related to architecture detection
# +relay,+snoop is very verbose - we filter to relevant functions
export WINEDEBUG="+relay"

echo "Starting trace (filtering for architecture-related APIs)..."
echo "Log will be saved to: $LOG_DIR/relay-trace.txt"
echo ""

# Run with timeout and filter
timeout 60 wine "$INSTALLER" 2>&1 | \
    grep -iE "IsWow64|GetNativeSystemInfo|GetSystemInfo|PROCESSOR|GetVersionEx|RtlGetVersion|VerifyVersionInfo|wProcessorArchitecture|GetSystemWow64Directory" | \
    head -500 > "$LOG_DIR/relay-trace.txt" &

WINE_PID=$!

# Also capture full log in background
timeout 60 wine "$INSTALLER" > "$LOG_DIR/full-wine-output.txt" 2>&1 || true

wait $WINE_PID 2>/dev/null || true

echo ""
echo "============================================================"
echo "Diagnostic Complete!"
echo "============================================================"
echo ""
echo "Log files created in: $LOG_DIR/"
echo ""
echo "Key files to examine:"
echo "  - wow64-test-results.txt   : WoW64 API test results"
echo "  - relay-trace.txt          : Filtered API calls"
echo "  - full-wine-output.txt     : Complete Wine output"
echo "  - registry-*.txt           : Registry state"
echo ""
echo "To analyze:"
echo "  cat $LOG_DIR/wow64-test-results.txt"
echo "  grep -i 'wow64\|processor\|getnative' $LOG_DIR/relay-trace.txt | head -50"
