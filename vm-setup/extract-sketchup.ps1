# SketchUp 2026 Extraction Script for Windows VM
# Run this in PowerShell after installing SketchUp
#
# This script copies all SketchUp files to a shared folder
# so they can be imported into Wine/Bottles on Linux

param(
    [string]$OutputPath = "Z:\sketchup-extraction"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SketchUp 2026 Extraction Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator (recommended)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "! Running without Administrator privileges" -ForegroundColor Yellow
    Write-Host "  Some files may not be accessible. Consider running as Admin." -ForegroundColor Yellow
    Write-Host ""
}

# Verify SketchUp is installed
$sketchupPath = "C:\Program Files\SketchUp\SketchUp 2026"
if (-not (Test-Path $sketchupPath)) {
    Write-Host "X SketchUp 2026 not found at: $sketchupPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install SketchUp 2026 first, then run this script again."
    exit 1
}
Write-Host "OK Found SketchUp 2026 installation" -ForegroundColor Green

# Check output path
Write-Host ""
Write-Host "Output directory: $OutputPath"

# If Z: drive doesn't exist, try to help
if ($OutputPath.StartsWith("Z:\") -and -not (Test-Path "Z:\")) {
    Write-Host ""
    Write-Host "! Shared folder (Z:) not mounted" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To mount the shared folder, run:" -ForegroundColor Cyan
    Write-Host '  net use Z: \\192.168.122.1\vm-shared'
    Write-Host ""
    Write-Host "Or specify a different output path:"
    Write-Host "  .\extract-sketchup.ps1 -OutputPath C:\sketchup-extraction"
    Write-Host ""

    $response = Read-Host "Use C:\sketchup-extraction instead? (y/n)"
    if ($response -eq 'y') {
        $OutputPath = "C:\sketchup-extraction"
    } else {
        exit 1
    }
}

# Create output directory
Write-Host ""
Write-Host "Creating extraction directory..."
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputPath\Program Files\SketchUp" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputPath\AppData\Roaming" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputPath\AppData\Local" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputPath\ProgramData" | Out-Null
Write-Host "OK Directory structure created" -ForegroundColor Green

# Copy Program Files
Write-Host ""
Write-Host "Copying Program Files (this may take a few minutes)..."
try {
    Copy-Item -Recurse -Force "$sketchupPath" "$OutputPath\Program Files\SketchUp\"
    $size = (Get-ChildItem -Recurse "$OutputPath\Program Files\SketchUp" | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "OK Program Files copied ($([math]::Round($size, 1)) MB)" -ForegroundColor Green
} catch {
    Write-Host "X Failed to copy Program Files: $_" -ForegroundColor Red
}

# Copy AppData Roaming
$username = $env:USERNAME
$appDataRoaming = "C:\Users\$username\AppData\Roaming\SketchUp"
if (Test-Path $appDataRoaming) {
    Write-Host ""
    Write-Host "Copying AppData\Roaming..."
    try {
        Copy-Item -Recurse -Force $appDataRoaming "$OutputPath\AppData\Roaming\"
        Write-Host "OK AppData\Roaming copied" -ForegroundColor Green
    } catch {
        Write-Host "! Could not copy AppData\Roaming: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "- AppData\Roaming not found (OK if SketchUp hasn't been launched)" -ForegroundColor Gray
}

# Copy AppData Local
$appDataLocal = "C:\Users\$username\AppData\Local\SketchUp"
if (Test-Path $appDataLocal) {
    Write-Host ""
    Write-Host "Copying AppData\Local..."
    try {
        Copy-Item -Recurse -Force $appDataLocal "$OutputPath\AppData\Local\"
        Write-Host "OK AppData\Local copied" -ForegroundColor Green
    } catch {
        Write-Host "! Could not copy AppData\Local: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "- AppData\Local not found (OK if SketchUp hasn't been launched)" -ForegroundColor Gray
}

# Copy ProgramData
$programData = "C:\ProgramData\SketchUp"
if (Test-Path $programData) {
    Write-Host ""
    Write-Host "Copying ProgramData..."
    try {
        Copy-Item -Recurse -Force $programData "$OutputPath\ProgramData\"
        Write-Host "OK ProgramData copied" -ForegroundColor Green
    } catch {
        Write-Host "! Could not copy ProgramData: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "- ProgramData not found" -ForegroundColor Gray
}

# Export Registry
Write-Host ""
Write-Host "Exporting registry keys..."

try {
    reg export "HKEY_LOCAL_MACHINE\SOFTWARE\SketchUp" "$OutputPath\sketchup-hklm.reg" /y 2>$null
    Write-Host "OK HKLM\SOFTWARE\SketchUp exported" -ForegroundColor Green
} catch {
    Write-Host "- HKLM registry key not found" -ForegroundColor Gray
}

try {
    reg export "HKEY_CURRENT_USER\SOFTWARE\SketchUp" "$OutputPath\sketchup-hkcu.reg" /y 2>$null
    Write-Host "OK HKCU\SOFTWARE\SketchUp exported" -ForegroundColor Green
} catch {
    Write-Host "- HKCU registry key not found" -ForegroundColor Gray
}

# Create manifest
Write-Host ""
Write-Host "Creating file manifest..."
Get-ChildItem -Recurse $OutputPath |
    Select-Object FullName, Length, LastWriteTime |
    Export-Csv "$OutputPath\manifest.csv" -NoTypeInformation
Write-Host "OK Manifest created" -ForegroundColor Green

# Calculate total size
$totalSize = (Get-ChildItem -Recurse $OutputPath | Measure-Object -Property Length -Sum).Sum / 1MB

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Extraction Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output directory: $OutputPath"
Write-Host "Total size: $([math]::Round($totalSize, 1)) MB"
Write-Host ""
Write-Host "Files extracted:"
Write-Host "  - Program Files\SketchUp\SketchUp 2026\"
Write-Host "  - AppData\Roaming\SketchUp\ (if present)"
Write-Host "  - AppData\Local\SketchUp\ (if present)"
Write-Host "  - ProgramData\SketchUp\ (if present)"
Write-Host "  - Registry exports (.reg files)"
Write-Host "  - manifest.csv"
Write-Host ""
Write-Host "Next steps on Linux:" -ForegroundColor Cyan
Write-Host "  cd /path/to/HOLYFUCKINGWINE"
Write-Host "  ./copy-from-windows.sh ~/vm-shared/sketchup-extraction"
Write-Host ""
