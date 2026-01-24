# SketchUp 2026 Activation Guide - Complete Offline Process

## Emergency Guide: When You Don't Have Internet/My Help

This guide covers the complete process from VM boot to SketchUp running in Linux Bottles.

---

## 🚀 PHASE 1: Start Windows VM

### Command to start VM:
```bash
virsh start windows11-basic
virt-viewer windows11-basic
```

### If VM doesn't start:
```bash
virsh list --all                    # Check status
virsh start windows11-basic        # Try again
virt-viewer windows11-basic        # Open viewer
```

---

## 📥 PHASE 2: Install SketchUp 2026

### Option A: Download in Windows (if internet works)
1. Open Edge browser
2. Go to: `https://www.sketchup.com/download/all`
3. Download "SketchUp Pro 2026"
4. Run installer, complete installation

### Option B: Use Pre-downloaded Installer (if no internet)
1. If you have the installer on Linux: `~/vm-shared/SketchUp-2026-1-189-46.exe`
2. Transfer via USB drive or other method
3. Run the installer in Windows

### Installation Steps:
1. Run `SketchUp-2026-1-189-46.exe`
2. Click "Install"
3. Skip Trimble account (optional)
4. Complete installation
5. **Don't launch SketchUp yet**

---

## 📋 PHASE 3: Run Extraction Script

### Short Extraction Script (type this in PowerShell):

```powershell
# Check installation
$path = "C:\Program Files\SketchUp\SketchUp 2026"
if (!(Test-Path $path)) { Write-Host "Install SketchUp first!"; exit }

# Create output
$out = "C:\sketchup-extraction"
New-Item -ItemType Directory -Force -Path $out | Out-Null
New-Item -ItemType Directory -Force -Path "$out\Program Files\SketchUp" | Out-Null

# Copy files
Copy-Item -Recurse -Force $path "$out\Program Files\SketchUp\"
$user = $env:USERNAME
Copy-Item -Recurse -Force "C:\Users\$user\AppData\Roaming\SketchUp" "$out\AppData\Roaming\" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "C:\Users\$user\AppData\Local\SketchUp" "$out\AppData\Local\" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "C:\ProgramData\SketchUp" "$out\ProgramData\" -ErrorAction SilentlyContinue

# Export registry
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\SketchUp" "$out\sketchup.reg" /y

Write-Host "EXTRACTION COMPLETE! Files in: $out"
```

### How to run:
1. Open PowerShell (search in Start menu)
2. Type the script above
3. Press Enter
4. Wait for "EXTRACTION COMPLETE!"

---

## 📤 PHASE 4: Transfer Files to Linux

### Method 1: USB Drive (Recommended)
1. Insert USB drive into Linux
2. Copy `C:\sketchup-extraction` folder to USB
3. On Linux: Copy from USB to `~/vm-shared/sketchup-extraction`

### Method 2: If Network Works
1. In Windows: Share the `C:\sketchup-extraction` folder
2. On Linux: Access via network share or scp

### Method 3: Shutdown VM and Access Disk
1. Shutdown Windows VM: `shutdown /s /t 0`
2. On Linux: Access VM disk directly (advanced)

---

## 🏠 PHASE 5: Import to Bottles

### On Linux:
```bash
cd /path/to/HOLYFUCKINGWINE
./copy-from-windows.sh ~/vm-shared/sketchup-extraction
```

### In Bottles GUI:
1. Open Bottles
2. Go to your SketchUp bottle
3. Check that files are in: `drive_c/Program Files/SketchUp/SketchUp 2026/`
4. Run `SketchUp.exe`

---

## 🔧 TROUBLESHOOTING

### VM Won't Start:
```bash
virsh destroy windows11-basic  # Force stop
virsh start windows11-basic    # Restart
virt-viewer windows11-basic    # Connect
```

### SketchUp Not Found:
- Check: `C:\Program Files\SketchUp\SketchUp 2026\`
- Reinstall if missing

### Extraction Fails:
- Run PowerShell as Administrator
- Check available disk space
- Try: `C:\temp-extraction` as output path

### Bottles Won't Import:
- Check file permissions
- Try: `chmod -R 755 ~/vm-shared/sketchup-extraction`

---

## 📞 EMERGENCY CONTACTS

If completely stuck:
1. Check this guide again
2. Try restarting VM: `virsh destroy windows11-basic && virsh start windows11-basic`
3. Verify files exist in expected locations
4. Check disk space: `df -h`

---

## ✅ SUCCESS CHECKLIST

- [ ] VM starts with `virt-viewer windows11-basic`
- [ ] SketchUp installs to `C:\Program Files\SketchUp\SketchUp 2026\`
- [ ] Extraction script runs without errors
- [ ] Files appear in `C:\sketchup-extraction`
- [ ] Files copied to Linux `~/vm-shared/sketchup-extraction`
- [ ] `./copy-from-windows.sh` completes successfully
- [ ] SketchUp launches in Bottles

**Created: 2026-01-23**
**For: HOLYFUCKINGWINE SketchUp 2026 Project**