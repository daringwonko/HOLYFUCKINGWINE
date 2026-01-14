# SketchUp 2026 Wine Setup - Complete Installation Checklist

## 📋 Pre-Installation Checklist

- [ ] **OS:** Fedora 42 Workstation installed
- [ ] **Internet:** Connection available for package downloads
- [ ] **Storage:** At least 50GB free space
  ```bash
  df -h ~
  ```
- [ ] **Sudo:** Able to run `sudo` commands
  ```bash
  sudo -l
  ```
- [ ] **NVIDIA Drivers:** Installed and working
  ```bash
  nvidia-smi
  ```

## 🚀 Installation Steps

### Step 1: Prepare Repository
- [ ] Clone HOLYFUCKINGWINE repository
- [ ] Navigate to directory: `cd HOLYFUCKINGWINE/sketchup-wine-setup`
- [ ] Make scripts executable: `chmod +x scripts/*.sh`
- [ ] Verify scripts are executable: `ls -l scripts/*.sh`

### Step 2: Run Master Setup (20-30 minutes)
- [ ] Execute: `./scripts/00-master-setup.sh`
- [ ] Watch for these messages:
  - ✓ Wine installed: (version 10.0 or 9.0)
  - ✓ Dependencies installed
  - ✓ WINEPREFIX created
  - ✓ .NET 4.8 installed
  - ✓ WebView2 installed
  - ✓ DXVK/VKD3D installed

**Troubleshooting this step:**
- [ ] No `wine` command? Script will install it from WineHQ repo
- [ ] dnf command not found? Not Fedora - may need adjustments
- [ ] Disk space errors? Free up ~25GB and try again

### Step 3: Verify Installation
- [ ] Execute: `./scripts/verify-setup.sh`
- [ ] All checks should be ✓ (green)
- [ ] If warnings: Non-critical, usually safe to continue
- [ ] If errors: Go back to Step 2

### Step 4: Install SketchUp
- [ ] Prepare: Have SketchUp 2026 installer ready (.exe file)
  - Location: `/home/tomas/SketchUp 2026/` (or any path)
- [ ] Execute: `./scripts/04-install-sketchup.sh`
- [ ] Script will find installer automatically
- [ ] Click through installer GUI (same as Windows)
- [ ] Wait for installation to complete
- [ ] Verify: `ls ~/.sketchup2026/drive_c/Program\ Files/SketchUp/`

**Troubleshooting this step:**
- [ ] Installer not found? Provide path when prompted
- [ ] Installer won't run? Pre-dependencies may be missing (run Step 2 again)
- [ ] Installation hangs? Can take 5-10 minutes, be patient

### Step 5: Launch SketchUp
- [ ] Execute: `./scripts/03-launch-sketchup.sh`
- [ ] Wait 30-60 seconds for SketchUp to start
- [ ] Trimble Identity login should appear (WebView2)
- [ ] Log in with your Trimble account
- [ ] SketchUp should open and load

**First launch notes:**
- [ ] Takes longer than normal (first startup)
- [ ] May see license validation screen
- [ ] Graphics initialization may take 10-20 seconds
- [ ] GPU may appear in NVIDIA control panel

**Troubleshooting this step:**
- [ ] SketchUp not found? Run Step 4
- [ ] WebView2 login won't appear? See Troubleshooting section
- [ ] Slow performance? Check GPU with `nvidia-smi`

## ✅ Post-Installation Verification

### Verify Wine
- [ ] Check version: `wine --version` (should be 9.0 or 10.0)
- [ ] Check prefix: `ls ~/.sketchup2026/` (should have drive_c, etc.)

### Verify Dependencies
- [ ] Run: `./scripts/verify-setup.sh`
- [ ] Check all items are ✓ or ⚠ (not ✗)

### Verify GPU
- [ ] Check GPU: `nvidia-smi`
- [ ] In SketchUp, Settings → OpenGL should show NVIDIA GPU
- [ ] Performance should be reasonable for your GPU

### Verify SketchUp
- [ ] Open a new document
- [ ] Create a simple shape (box, circle, etc.)
- [ ] Rotate view with mouse (should be smooth)
- [ ] Try rendering or shadow view

## 🔧 Configuration

### Environment Variables (Set Automatically)
These are set by all scripts automatically. You don't need to do this manually.

```bash
export WINEPREFIX="~/.sketchup2026"
export WINEARCH=win64
export WINEDEBUG=-all
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
```

### Manual Configuration (If Needed)
- [ ] Edit GPU settings: `nvidia-settings`
- [ ] Adjust SketchUp OpenGL: SketchUp Settings → OpenGL
- [ ] Modify Wine settings: `winetricks prefix`

## 📊 Disk Space Usage

### Approximate Storage Requirements
| Component | Size |
|-----------|------|
| Wine + Libraries | 8-10 GB |
| .NET Framework 4.8 | 1-2 GB |
| WebView2 | 0.5-1 GB |
| DXVK/VKD3D | 0.5 GB |
| SketchUp 2026 | 5-8 GB |
| **Total** | **~20-25 GB** |

- [ ] Verify disk space before starting: `df -h ~`
- [ ] Monitor during installation: `du -sh ~/.sketchup2026`

## 🐛 Common Issues Checklist

### Wine Installation Issues
- [ ] "dnf: command not found" → Not Fedora or not in container
- [ ] "Permission denied" → Run with `sudo`
- [ ] "Repository not found" → Internet connection issue

### WINEPREFIX Creation Issues
- [ ] "Wine prefix already exists" → Old prefix backed up, continuing
- [ ] "Not enough space" → Free up 25GB minimum
- [ ] "Permission denied" → Check `~` directory permissions

### Dependency Installation Issues
- [ ] ".NET 4.8 installation failed" → Normal, usually works on retry
- [ ] "WebView2 timeout" → Slow internet, let it run 10+ minutes
- [ ] "DXVK not found" → Package missing from repository

### SketchUp Installation Issues
- [ ] "SketchUp not found" → Provide path to installer
- [ ] "Installer won't run" → Missing dependencies (rerun Step 2)
- [ ] "Installation hangs" → Patient, can take 10-15 minutes

### SketchUp Launch Issues
- [ ] "SketchUp not in prefix" → Rerun Step 4
- [ ] "WebView2 login missing" → Wait 1-2 minutes
- [ ] "Slow performance" → Check GPU with `nvidia-smi`
- [ ] "Graphics corrupted" → Update NVIDIA drivers

## 📚 Documentation References

For detailed information, see:
- [ ] **Full Setup Guide:** `sketchup-wine-setup/docs/README.md`
- [ ] **GPU Offloading:** `sketchup-wine-setup/docs/NVIDIA-GPU-OFFLOADING.md`
- [ ] **Troubleshooting:** `sketchup-wine-setup/docs/TROUBLESHOOTING.md`
- [ ] **Components:** `sketchup-wine-setup/docs/WINETRICKS-COMPONENTS.md`

## 🎯 Success Criteria

Your installation is successful when:

- [ ] ✓ `wine --version` shows 9.0 or 10.0
- [ ] ✓ `~/.sketchup2026` directory exists and is ~20GB
- [ ] ✓ SketchUp.exe exists in `~/.sketchup2026/drive_c/Program Files/`
- [ ] ✓ `./scripts/verify-setup.sh` shows all green ✓
- [ ] ✓ `./scripts/03-launch-sketchup.sh` launches SketchUp
- [ ] ✓ You can log in with Trimble Identity
- [ ] ✓ You can create and edit sketches
- [ ] ✓ 3D view renders smoothly with NVIDIA GPU

## 🔄 Maintenance

### Weekly
- [ ] No maintenance needed
- [ ] SketchUp works normally

### Monthly
- [ ] Check for Wine updates: `sudo dnf update wine-stable`
- [ ] Check for NVIDIA driver updates: `nvidia-smi -q`

### Quarterly
- [ ] Update SketchUp: Help → Check for Updates
- [ ] Backup user data: `~/.sketchup2026/drive_c/users/`

### Yearly
- [ ] Fresh SketchUp installation if major version released
- [ ] Fresh Wine prefix if performance degrades

## 📞 Support

If issues persist:

1. [ ] Run `./scripts/verify-setup.sh` and save output
2. [ ] Check `sketchup-wine-setup/docs/TROUBLESHOOTING.md`
3. [ ] Search WineHQ forums: https://forums.winehq.org
4. [ ] Check NVIDIA driver compatibility

---

**Checklist Version:** 1.0  
**Last Updated:** January 13, 2026  
**For:** SketchUp 2026 on Fedora 42 + NVIDIA Hybrid Graphics
