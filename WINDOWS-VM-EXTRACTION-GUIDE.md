# SketchUp 2026 Windows VM Extraction Guide

## Purpose

This guide provides step-by-step instructions for installing SketchUp 2026 in a Windows VM, then extracting and transferring the installed files to a Linux Wine/Bottles environment.

**Why this approach?** The SketchUp 2026 installer uses InstallShield 2024 Suite format which calls Windows Update Agent COM interfaces (`IWindowsUpdateAgentInfo`) that Wine does not implement. The installer itself cannot run, but the *installed application* can run fine under Wine with proper dependencies.

---

## Prerequisites

### On Linux (Target System)
- Bottles installed (Flatpak recommended)
- A Bottles prefix with these dependencies installed:
  - `dotnet48` (.NET Framework 4.8)
  - `vcrun2017` (Visual C++ 2017 Runtime)
  - `webview2` (Microsoft Edge WebView2 - for Trimble login)
  - `dxvk` (DirectX to Vulkan translation)
  - `corefonts` (Microsoft Core Fonts)
- NVIDIA drivers configured (if using NVIDIA GPU)

### On Windows VM
- Windows 10 or 11 VM (VirtualBox, VMware, QEMU/KVM, etc.)
- Minimum 8GB RAM allocated to VM
- ~10GB free disk space
- SketchUp 2026 installer (`SketchUp-2026-x-xxx-xx.exe`)
- Guest Additions/Tools installed for shared folders

---

## Phase 1: Windows VM Setup

### Step 1.1: Create Shared Folder

Set up a shared folder between host (Linux) and guest (Windows):

**VirtualBox:**
```bash
# On Linux host
mkdir -p ~/vm-shared
# In VirtualBox: Settings → Shared Folders → Add
# Folder Path: /home/yourusername/vm-shared
# Folder Name: shared
# Check "Auto-mount" and "Make Permanent"
```

**VMware:**
```bash
# On Linux host
mkdir -p ~/vm-shared
# In VMware: VM → Settings → Options → Shared Folders
# Add folder: /home/yourusername/vm-shared
```

**QEMU/virt-manager:**
```bash
# Use virtio-9p or set up Samba share
mkdir -p ~/vm-shared
# In virt-manager: Add Hardware → Filesystem
# Driver: virtio-9p, Source: /home/yourusername/vm-shared, Target: shared
```

### Step 1.2: Boot Windows VM

1. Start the Windows VM
2. Verify shared folder is accessible (usually appears as network drive or under "This PC")
3. Copy the SketchUp installer to the VM (via shared folder or download directly)

---

## Phase 2: Install SketchUp in Windows

### Step 2.1: Run Installer

1. Double-click `SketchUp-2026-x-xxx-xx.exe`
2. Accept license agreement
3. **IMPORTANT:** Note the installation path (default: `C:\Program Files\SketchUp\SketchUp 2026`)
4. Complete installation normally
5. **Do NOT launch SketchUp yet** (skip the "Launch SketchUp" checkbox at the end)

### Step 2.2: Locate Installed Files

Open File Explorer and navigate to the installation directory:

```
C:\Program Files\SketchUp\SketchUp 2026\
```

You should see a structure similar to:
```
SketchUp 2026/
├── SketchUp.exe              # Main executable
├── SketchUp.dll              # Core library
├── LayOut.exe                # LayOut application
├── Style Builder.exe         # Style Builder application
├── Resources/                # Resource files
├── Plugins/                  # Ruby plugins
├── Tools/                    # Additional tools
├── ShippedExtensions/        # Bundled extensions
└── [various DLLs]            # Runtime dependencies
```

### Step 2.3: Locate Additional Required Directories

SketchUp also installs files in these locations:

**User AppData (per-user data):**
```
C:\Users\<YourUsername>\AppData\Roaming\SketchUp\SketchUp 2026\
```

**Local AppData (caches, WebView2):**
```
C:\Users\<YourUsername>\AppData\Local\SketchUp\SketchUp 2026\
```

**ProgramData (shared data):**
```
C:\ProgramData\SketchUp\SketchUp 2026\
```

---

## Phase 3: Extract Files to Shared Folder

### Step 3.1: Create Archive Structure

Open PowerShell as Administrator and run:

```powershell
# Create staging directory
$staging = "Z:\sketchup-extraction"  # Adjust drive letter for your shared folder
New-Item -ItemType Directory -Force -Path $staging

# Create subdirectories
New-Item -ItemType Directory -Force -Path "$staging\Program Files\SketchUp"
New-Item -ItemType Directory -Force -Path "$staging\AppData\Roaming\SketchUp"
New-Item -ItemType Directory -Force -Path "$staging\AppData\Local\SketchUp"
New-Item -ItemType Directory -Force -Path "$staging\ProgramData\SketchUp"
```

### Step 3.2: Copy Program Files

```powershell
# Copy main installation
Copy-Item -Recurse -Force "C:\Program Files\SketchUp\SketchUp 2026" "$staging\Program Files\SketchUp\"

# Verify copy
Get-ChildItem "$staging\Program Files\SketchUp\SketchUp 2026" | Format-Table Name, Length
```

### Step 3.3: Copy User Data

```powershell
$username = $env:USERNAME

# Copy Roaming AppData
if (Test-Path "C:\Users\$username\AppData\Roaming\SketchUp\SketchUp 2026") {
    Copy-Item -Recurse -Force "C:\Users\$username\AppData\Roaming\SketchUp\SketchUp 2026" "$staging\AppData\Roaming\SketchUp\"
}

# Copy Local AppData
if (Test-Path "C:\Users\$username\AppData\Local\SketchUp\SketchUp 2026") {
    Copy-Item -Recurse -Force "C:\Users\$username\AppData\Local\SketchUp\SketchUp 2026" "$staging\AppData\Local\SketchUp\"
}

# Copy ProgramData
if (Test-Path "C:\ProgramData\SketchUp\SketchUp 2026") {
    Copy-Item -Recurse -Force "C:\ProgramData\SketchUp\SketchUp 2026" "$staging\ProgramData\SketchUp\"
}
```

### Step 3.4: Export Registry Keys (Optional but Recommended)

```powershell
# Export SketchUp registry entries
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\SketchUp" "$staging\sketchup-hklm.reg" /y
reg export "HKEY_CURRENT_USER\SOFTWARE\SketchUp" "$staging\sketchup-hkcu.reg" /y

# Export file associations (optional)
reg export "HKEY_CLASSES_ROOT\.skp" "$staging\skp-association.reg" /y
```

### Step 3.5: Create Manifest

```powershell
# Create a manifest of all copied files
Get-ChildItem -Recurse "$staging" | Select-Object FullName, Length, LastWriteTime |
    Export-Csv "$staging\manifest.csv" -NoTypeInformation

Write-Host "Extraction complete! Files are in: $staging"
Write-Host "Total size:"
Get-ChildItem -Recurse "$staging" | Measure-Object -Property Length -Sum |
    Select-Object @{N='Size (MB)';E={[math]::Round($_.Sum/1MB,2)}}
```

---

## Phase 4: Import to Linux Bottles Environment

### Step 4.1: Locate Your Bottles Prefix

Find your Bottles prefix path:

```bash
# Standard Flatpak Bottles location
BOTTLES_BASE="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles"

# List existing bottles
ls -la "$BOTTLES_BASE"

# Your SketchUp bottle (adjust name as needed)
BOTTLE_PREFIX="$BOTTLES_BASE/SketchUp2026"
```

Or if using a custom location:
```bash
# Custom location example
BOTTLE_PREFIX="$HOME/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026"
```

### Step 4.2: Run the Copy Script

Use the provided `copy-from-windows.sh` script:

```bash
cd /path/to/HOLYFUCKINGWINE
./copy-from-windows.sh ~/vm-shared/sketchup-extraction "$BOTTLE_PREFIX"
```

Or manually copy:

```bash
# Set variables
EXTRACTION="$HOME/vm-shared/sketchup-extraction"
BOTTLE_PREFIX="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026"

# Copy Program Files
cp -r "$EXTRACTION/Program Files/SketchUp/SketchUp 2026" \
      "$BOTTLE_PREFIX/drive_c/Program Files/SketchUp/"

# Copy AppData (adjust username in prefix)
WINE_USER=$(ls "$BOTTLE_PREFIX/drive_c/users/" | grep -v -E '^(Public|steamuser)$' | head -1)

cp -r "$EXTRACTION/AppData/Roaming/SketchUp/SketchUp 2026" \
      "$BOTTLE_PREFIX/drive_c/users/$WINE_USER/AppData/Roaming/SketchUp/"

cp -r "$EXTRACTION/AppData/Local/SketchUp/SketchUp 2026" \
      "$BOTTLE_PREFIX/drive_c/users/$WINE_USER/AppData/Local/SketchUp/"

# Copy ProgramData
cp -r "$EXTRACTION/ProgramData/SketchUp/SketchUp 2026" \
      "$BOTTLE_PREFIX/drive_c/ProgramData/SketchUp/"
```

### Step 4.3: Import Registry Keys

```bash
# Convert registry files from UTF-16 to UTF-8 (Wine requirement)
cd "$EXTRACTION"
iconv -f UTF-16LE -t UTF-8 sketchup-hklm.reg > sketchup-hklm-utf8.reg
iconv -f UTF-16LE -t UTF-8 sketchup-hkcu.reg > sketchup-hkcu-utf8.reg

# Import via Wine
export WINEPREFIX="$BOTTLE_PREFIX"
wine regedit sketchup-hklm-utf8.reg
wine regedit sketchup-hkcu-utf8.reg
```

### Step 4.4: Set Permissions

```bash
# Ensure executables are marked executable (Wine doesn't always need this, but helps)
find "$BOTTLE_PREFIX/drive_c/Program Files/SketchUp" -name "*.exe" -exec chmod +x {} \;
```

---

## Phase 5: Configure and Launch

### Step 5.1: Create Launch Script

Create `launch-sketchup.sh`:

```bash
#!/bin/bash

# SketchUp 2026 Launch Script
BOTTLE_PREFIX="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026"
SKETCHUP_EXE="$BOTTLE_PREFIX/drive_c/Program Files/SketchUp/SketchUp 2026/SketchUp.exe"

# NVIDIA GPU Offloading (if using NVIDIA Optimus laptop)
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

# Wine environment
export WINEPREFIX="$BOTTLE_PREFIX"
export WINEDLLOVERRIDES="winemenubuilder.exe=d"

# For Bottles with Soda runner
WINE="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1/bin/wine"

# Launch
"$WINE" "$SKETCHUP_EXE" "$@"
```

### Step 5.2: Test Launch

```bash
chmod +x launch-sketchup.sh
./launch-sketchup.sh
```

### Step 5.3: Troubleshooting First Launch

**If it crashes immediately:**
```bash
# Enable debug output
WINEDEBUG=+loaddll,+module ./launch-sketchup.sh 2>&1 | tee sketchup-debug.log
```

**If it shows DLL errors:**
```bash
# Check which DLLs are missing
grep -i "could not load" sketchup-debug.log
# Install missing components via winetricks
```

**If Trimble login fails:**
- Ensure WebView2 is installed in the prefix
- Check if `msedgewebview2` process starts
- May need to install `webview2` via Bottles dependencies

---

## Phase 6: Verification Checklist

After setup, verify these work:

- [ ] SketchUp.exe launches without crash
- [ ] Main window appears with 3D viewport
- [ ] Can create new document
- [ ] Can draw basic shapes (rectangle, circle)
- [ ] 3D navigation works (orbit, pan, zoom)
- [ ] Trimble login dialog appears (for license activation)
- [ ] Can save .skp files
- [ ] Can open existing .skp files
- [ ] LayOut.exe launches (if needed)
- [ ] GPU acceleration working (check FPS in complex scenes)

---

## Appendix A: Directory Structure Reference

After successful import, your Bottles prefix should contain:

```
$BOTTLE_PREFIX/
├── drive_c/
│   ├── Program Files/
│   │   └── SketchUp/
│   │       └── SketchUp 2026/
│   │           ├── SketchUp.exe
│   │           ├── LayOut.exe
│   │           └── [all program files]
│   ├── ProgramData/
│   │   └── SketchUp/
│   │       └── SketchUp 2026/
│   └── users/
│       └── [username]/
│           └── AppData/
│               ├── Local/
│               │   └── SketchUp/
│               └── Roaming/
│                   └── SketchUp/
├── system.reg
├── user.reg
└── userdef.reg
```

---

## Appendix B: Common Issues and Solutions

### Issue: "Application failed to initialize properly"
**Cause:** Missing .NET Framework or VC++ Runtime
**Solution:** Ensure `dotnet48` and `vcrun2017` are installed in Bottles

### Issue: Black screen / No 3D rendering
**Cause:** DXVK not configured or GPU not detected
**Solution:**
1. Verify DXVK is enabled in Bottles
2. Check `vulkaninfo` works on host
3. Add NVIDIA environment variables

### Issue: "Network error" on Trimble login
**Cause:** WebView2 not working correctly
**Solution:**
1. Reinstall `webview2` dependency
2. Check if `msedgewebview2.exe` appears in process list
3. Try running SketchUp in offline mode first

### Issue: Slow performance / Low FPS
**Cause:** Running on integrated GPU instead of discrete
**Solution:** Add NVIDIA PRIME offload environment variables (see launch script)

### Issue: Ruby plugins not loading
**Cause:** Plugin path not set correctly
**Solution:** Copy plugins to:
```
$BOTTLE_PREFIX/drive_c/users/[username]/AppData/Roaming/SketchUp/SketchUp 2026/Plugins/
```

---

## Appendix C: Enterprise MSI Alternative

If you have access to Trimble enterprise support, you can request a standalone MSI installer:

1. Contact Trimble sales or your account manager
2. Request "SketchUp 2026 MSI deployment package"
3. Enterprise MSI installers do not use InstallShield Suite wrapper
4. Can be installed directly via: `wine msiexec /i SketchUp2026.msi`

---

## Document Information

- **Created:** 2026-01-23
- **Purpose:** Windows VM extraction workflow for SketchUp 2026 on Linux
- **Target Environment:** Fedora 42, Bottles with Soda runner, NVIDIA GTX 1050 Ti
- **Repository:** HOLYFUCKINGWINE

*This guide was created after extensive debugging revealed that Wine cannot run the InstallShield 2024 installer due to missing Windows Update Agent COM interface implementation.*
