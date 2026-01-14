# Quick Start Guide - SketchUp 2026 on Wine

## 30-Second Overview

You have a complete Wine setup package for SketchUp 2026 with GPU offloading to your NVIDIA GTX 1050 Ti.

### System
- **OS:** Fedora 42
- **GPU:** NVIDIA GTX 1050 Ti (Intel HD 630 bypassed)
- **Wine:** Official WineHQ Stable 10.0 or 9.0
- **Prefix Location:** `~/.wine/sketchup2026/` (portable, can be copied to other Fedora systems)

---

## Four Ways to Get Started

### Option 1: Automatic Setup (Recommended)

Run everything automatically:

```bash
cd scripts
chmod +x 00-master-setup.sh
sudo ./00-master-setup.sh
```

This installs Wine, creates the prefix, and installs all dependencies in one command.
**Time:** 30-45 minutes (mostly waiting for components)

---

### Option 2: Step-by-Step Manual

Run each step individually for more control:

```bash
# Step 1: Install WineHQ
cd scripts
chmod +x 01-install-winehq.sh
sudo ./01-install-winehq.sh

# Step 2: Create Wine prefix and install dependencies
chmod +x 02-setup-wineprefix.sh
./02-setup-wineprefix.sh

# Step 3: Launch SketchUp
chmod +x 03-launch-sketchup.sh
./03-launch-sketchup.sh
```

---

### Option 3: Use Existing WineHQ Installation

If you already have WineHQ 10.0+ installed on your system:

```bash
# Just create the prefix and dependencies
cd scripts
chmod +x 02-setup-wineprefix.sh
./02-setup-wineprefix.sh

# Launch SketchUp
chmod +x 03-launch-sketchup.sh
./03-launch-sketchup.sh
```

---

### Option 4: Install SketchUp into Wine

If you want to install SketchUp from the installer:

```bash
cd scripts

# First: Set up the prefix
chmod +x 02-setup-wineprefix.sh
./02-setup-wineprefix.sh

# Then: Run the installer
chmod +x 04-install-sketchup.sh
./04-install-sketchup.sh
```

---

## Launching SketchUp After Setup

Once setup is complete, simply run:

```bash
cd scripts
./03-launch-sketchup.sh
```

The script automatically:
- Sets `WINEPREFIX` to `~/.wine/sketchup2026`
- Enables GPU offloading (`__NV_PRIME_RENDER_OFFLOAD=1`)
- Forces NVIDIA GPU (`__GLX_VENDOR_LIBRARY_NAME=nvidia`)
- Launches SketchUp with all settings configured

---

## What Gets Installed

### Wine Components
- **WineHQ Stable** (Version 10.0 or 9.0)
- **Winetricks** (Dependency manager)
- **Wine-64bit** architecture

### SketchUp Dependencies
- **dotnet48** - .NET Framework 4.8 (SketchUp core)
- **vcrun2017** - Visual C++ 2017 Runtime
- **webview2** - Trimble Identity login screen
- **dxvk** - DirectX 10/11/12 via Vulkan
- **vkd3d** - Direct3D 12 support

### System Libraries
- 32-bit and 64-bit Vulkan loaders
- Linux OpenGL support

---

## Disk Space

Total disk space used:
- Base Wine prefix: 100 MB
- All dependencies: 800 MB
- SketchUp 2026: 1.2 GB (if installed in prefix)
- **Total: ~2-3 GB**

Make sure you have at least 3-4 GB available in your home directory.

---

## Verification Checklist

After installation, verify everything works:

```bash
# 1. Check Wine is installed
wine --version
# Should show: Wine 10.0 (Staging) or Wine 9.0

# 2. Verify GPU offloading
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep renderer
# Should show: NVIDIA GeForce GTX 1050 Ti

# 3. Check all dependencies installed
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks list-installed | grep -E "dotnet48|vcrun2017|webview2|dxvk|vkd3d"

# 4. Launch SketchUp
./scripts/03-launch-sketchup.sh
# Should open SketchUp with Trimble login
```

---

## Troubleshooting

### Wine won't install
- Check internet connection: `ping 8.8.8.8`
- Try COPR repo: `sudo dnf copr enable sentry/wine`
- Or use Bottles: `flatpak install com.usebottles.bottles`

### SketchUp won't launch
- Check prefix exists: `ls ~/.wine/sketchup2026/system.reg`
- Check dependencies: `export WINEPREFIX="$HOME/.wine/sketchup2026"; winetricks list-installed`
- See full docs: `docs/TROUBLESHOOTING.md`

### GPU offloading not working
- Verify NVIDIA driver: `nvidia-smi`
- Check system has Wayland or X11: `echo $XDG_SESSION_TYPE`
- See GPU guide: `docs/NVIDIA-GPU-OFFLOADING.md`

### WebView2 installation hangs
- **This is NORMAL** - WebView2 takes 10-15 minutes
- Check progress: `ps aux | grep wine`
- Let it run for 20 minutes before interrupting

---

## File Structure

```
sketchup-wine-setup/
│
├── scripts/
│   ├── 00-master-setup.sh      ← Run this for automatic setup
│   ├── 01-install-winehq.sh    ← Install WineHQ repo + wine
│   ├── 02-setup-wineprefix.sh  ← Create prefix + dependencies
│   ├── 03-launch-sketchup.sh   ← Launch SketchUp (run this!)
│   └── 04-install-sketchup.sh  ← Run SketchUp installer
│
├── docs/
│   ├── README.md                    ← Full setup guide
│   ├── NVIDIA-GPU-OFFLOADING.md     ← GPU configuration
│   ├── WINETRICKS-COMPONENTS.md     ← Component details
│   └── TROUBLESHOOTING.md           ← Problem solving
│
└── config/
    └── (Optional: custom Wine configs)
```

---

## Key Environment Variables

The launch scripts automatically set these:

```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"
export WINEARCH=win64
export __NV_PRIME_RENDER_OFFLOAD=1          # Use NVIDIA GPU
export __GLX_VENDOR_LIBRARY_NAME=nvidia     # Force NVIDIA driver
```

---

## Transferring to Another System

To move this setup to your actual Fedora 42 laptop:

1. **Archive on this VM:**
   ```bash
   tar -czf sketchup2026-setup.tar.gz ~/sketchup-wine-setup/
   tar -czf sketchup2026-prefix.tar.gz ~/.wine/sketchup2026/
   ```

2. **Transfer files to laptop** (USB, cloud storage, etc.)

3. **On laptop:**
   ```bash
   # Extract scripts and docs
   tar -xzf sketchup2026-setup.tar.gz -C ~/
   
   # Extract Wine prefix
   tar -xzf sketchup2026-prefix.tar.gz -C ~/
   
   # Make scripts executable
   chmod +x ~/sketchup-wine-setup/scripts/*.sh
   
   # Launch SketchUp
   ~/sketchup-wine-setup/scripts/03-launch-sketchup.sh
   ```

---

## Advanced

### Bash Alias for Easy Launch

Add to `~/.bashrc`:

```bash
alias sketchup='export WINEPREFIX="$HOME/.wine/sketchup2026"; \
                export __NV_PRIME_RENDER_OFFLOAD=1; \
                export __GLX_VENDOR_LIBRARY_NAME=nvidia; \
                wine "/home/tomas/SketchUp 2026/SketchUp.exe"'
```

Then just type: `sketchup`

### Monitor GPU While Running

In separate terminal:

```bash
nvidia-smi dmon
# Shows real-time GPU usage
```

### Debug Mode

Enable detailed logging:

```bash
export WINEDEBUG=+all
./scripts/03-launch-sketchup.sh 2>&1 | tee sketchup-debug.log
```

---

## Support & Further Help

- **Full Setup Guide:** `docs/README.md`
- **GPU Configuration:** `docs/NVIDIA-GPU-OFFLOADING.md`
- **Component Details:** `docs/WINETRICKS-COMPONENTS.md`
- **Problem Solving:** `docs/TROUBLESHOOTING.md`

---

## Quick Reference Commands

```bash
# Check Wine version
wine --version

# Check GPU offloading is working
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep renderer

# List installed dependencies
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks list-installed

# Monitor GPU usage
nvidia-smi dmon

# Check NVIDIA driver
nvidia-smi

# Launch SketchUp
./scripts/03-launch-sketchup.sh
```

---

**That's it! You're ready to run SketchUp 2026 on Linux with full GPU acceleration.**

Start with: `./scripts/00-master-setup.sh` or follow Option 2 for step-by-step setup.

Have questions? Check the `docs/` folder for detailed information.
