# SketchUp 2026 on Wine - Complete Setup Guide

**System Configuration:**
- OS: Fedora 42 (Workstation)
- Laptop: Acer Nitro AN515-51
- CPU: Intel Core i7-7700HQ
- GPU: Intel HD 630 (iGPU) + NVIDIA GeForce GTX 1050 Ti
- Display Server: Wayland
- Wine: Official WineHQ Stable (10.0 or 9.0)

---

## Overview

This setup provides a complete, portable Wine environment for running SketchUp 2026 on Linux with full GPU offloading to your NVIDIA GTX 1050 Ti. All required dependencies are pre-configured in a clean, isolated Wine prefix (`~/.wine/sketchup2026`).

### Key Features
- ✅ Official WineHQ Stable from repository
- ✅ Clean 64-bit WINEPREFIX isolated from system Wine
- ✅ All required .NET/DirectX components pre-installed
- ✅ NVIDIA GPU offloading via `__NV_PRIME_RENDER_OFFLOAD`
- ✅ VKD3D + DXVK for DirectX 12 support
- ✅ WebView2 for Trimble Identity login
- ✅ Portable across systems (copy `~/.wine/sketchup2026`)

---

## Prerequisites

Before starting, ensure you have:
1. **Fedora 42** installed
2. **NVIDIA drivers** installed (`nvidia-smi` should work)
3. **Internet connection** to download packages and dependencies
4. **Sudo privileges** (required for package installation)

### Check Prerequisites

```bash
# Check Fedora version
cat /etc/fedora-release

# Check NVIDIA drivers
nvidia-smi

# Verify sudo access
sudo -l
```

---

## Installation Steps

### Step 1: Install WineHQ Stable

```bash
cd ./scripts
chmod +x 01-install-winehq.sh
sudo ./01-install-winehq.sh
```

**What this does:**
- Adds official WineHQ repository to system
- Installs `winehq-stable` (version 10.0 or 9.0)
- Installs `winetricks` for dependency management
- Installs system libraries and GPU drivers

**Expected output:**
```
Wine version X.0 (Staging)
```

**Troubleshooting:**
- If repository fails, it will suggest fallback options
- Ensure you have sufficient disk space (~2GB for Wine + dependencies)

---

### Step 2: Create and Configure WINEPREFIX

```bash
chmod +x 02-setup-wineprefix.sh
./02-setup-wineprefix.sh
```

**What this does:**
- Creates clean 64-bit Wine prefix at `~/.wine/sketchup2026`
- Sets Windows 10 compatibility
- Installs **dotnet48** (application core)
- Installs **vcrun2017** (Visual C++ 2017 runtime)
- Installs **webview2** (Trimble Identity browser component)
- Installs **dxvk** (DirectX 10/11/12 via Vulkan)
- Installs **vkd3d** (D3D12 shader compilation)

**Expected duration:** 5-15 minutes (dependencies download ~2GB)

**What you'll see:**
- Wine prefix initialization
- Winetricks installations with progress bars
- "WINEPREFIX Setup Complete" message at the end

---

### Step 3: Install SketchUp 2026 (If needed)

If you want to install SketchUp into the Wine prefix:

```bash
chmod +x 04-install-sketchup.sh
./04-install-sketchup.sh
```

**This will:**
1. Launch the SketchUp installer with GPU offloading enabled
2. Guide you through the installation wizard
3. Install to `~/.wine/sketchup2026/drive_c/Program Files/SketchUp/SketchUp 2026/`

**Note:** If you already have SketchUp on your system, you can skip this and directly run it via `03-launch-sketchup.sh`

---

### Step 4: Launch SketchUp

```bash
chmod +x 03-launch-sketchup.sh
./03-launch-sketchup.sh
```

**GPU Offloading Verification:**
- Check that SketchUp launches without Intel GPU lag
- Model loading should be fast and smooth
- No graphical glitches (indicates proper VKD3D rendering)

---

## Environment Variables Explained

### GPU Offloading (NVIDIA)

These variables are automatically set in the launch scripts:

```bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
```

**What they do:**
- `__NV_PRIME_RENDER_OFFLOAD=1`: Tells the system to use NVIDIA GPU for rendering
- `__GLX_VENDOR_LIBRARY_NAME=nvidia`: Forces OpenGL/Vulkan to use NVIDIA drivers
- Combined effect: Bypasses Intel HD 630, uses GTX 1050 Ti exclusively

### Wine Configuration

```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"  # Isolated prefix
export WINEARCH=win64                          # 64-bit Windows
export WINEDEBUG=-all                          # Disable debug output
```

---

## Wine Prefix Contents

After setup, your `~/.wine/sketchup2026/` directory contains:

```
.wine/sketchup2026/
├── drive_c/                    # Windows C: drive
│   ├── Program Files/          # Application installation directory
│   ├── Windows/                # Windows system files
│   ├── ProgramData/            # Application data
│   └── users/                  # User profiles
├── dosdevices/                 # Drive mappings
├── system.reg                  # Windows registry
├── user.reg                    # User registry
└── (other Wine configuration files)
```

---

## Transferring to Another System

### On the Source System (This VM)

1. Ensure prefix is fully configured and tested
2. Archive the prefix:
   ```bash
   tar -czf sketchup2026-prefix.tar.gz ~/.wine/sketchup2026/
   ```

3. Download all scripts and documentation:
   ```bash
   tar -czf sketchup-wine-setup.tar.gz ./sketchup-wine-setup/
   ```

### On the Target System (Your Fedora 42 Laptop)

1. Install WineHQ (if not already installed):
   ```bash
   sudo ./01-install-winehq.sh
   ```

2. Extract the prefix:
   ```bash
   tar -xzf sketchup2026-prefix.tar.gz -C ~/
   # This restores ~/.wine/sketchup2026/
   ```

3. Verify the setup:
   ```bash
   ls -la ~/.wine/sketchup2026/
   ```

4. Launch SketchUp:
   ```bash
   ./03-launch-sketchup.sh
   ```

---

## Troubleshooting

### SketchUp won't launch
- **Symptom:** Wine returns an error or nothing happens
- **Solution:** 
  ```bash
  WINEDEBUG=+all ./03-launch-sketchup.sh 2>&1 | tail -20
  ```
  This will show the last 20 lines of debug output

### Slow performance / Intel GPU is being used
- **Symptom:** SketchUp is laggy, fans not spinning up on NVIDIA
- **Solution:** Verify GPU offloading is active:
  ```bash
  __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep "OpenGL renderer"
  # Should show: "NVIDIA GeForce GTX 1050 Ti"
  ```

### Trimble Identity login fails
- **Symptom:** Login screen appears but can't log in
- **Solution:**
  - Verify WebView2 installation: `ls ~/.wine/sketchup2026/drive_c/Program\ Files/SketchUp/`
  - Run setup again: `./02-setup-wineprefix.sh`
  - Check network connectivity in Wine: `wine cmd /c ipconfig`

### WebView2 installation hangs
- **Symptom:** winetricks appears frozen during webview2
- **Solution:**
  - This is normal (can take 5-10 minutes)
  - Monitor system resources: `top` or `gnome-system-monitor`
  - If truly frozen for >15 min, kill and retry:
    ```bash
    killall wineserver
    sleep 2
    ./02-setup-wineprefix.sh
    ```

### Graphics corruption / crashes
- **Symptom:** SketchUp renders incorrectly or crashes
- **Solution:**
  1. Verify DXVK/VKD3D installation:
     ```bash
     export WINEPREFIX="$HOME/.wine/sketchup2026"
     winetricks list-installed | grep -E "dxvk|vkd3d"
     ```
  2. Reinstall graphics components:
     ```bash
     export WINEPREFIX="$HOME/.wine/sketchup2026"
     winetricks dxvk vkd3d
     ```

---

## Advanced Configuration

### Custom Wine Runner (Alternative to WineHQ)

If the WineHQ repository fails, you can use Flatpak Bottles:

```bash
# Install Bottles (Flatpak-based Wine runner)
flatpak install flathub com.usebottles.bottles

# Create a new Bottle for SketchUp
# (Use GUI for this, or see Bottles documentation)
```

### Persistent Environment Variables

To avoid typing environment variables every time, add to `~/.bashrc`:

```bash
# SketchUp 2026 Wine Configuration
export SKETCHUP_WINE_PREFIX="$HOME/.wine/sketchup2026"
export SKETCHUP_NVIDIA_GPU="1"

# Function to launch SketchUp easily
sketchup() {
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export WINEPREFIX="$SKETCHUP_WINE_PREFIX"
    wine "/home/tomas/SketchUp 2026/SketchUp.exe" "$@"
}
```

Then simply run: `sketchup`

### Monitor CPU/GPU Usage During SketchUp

```bash
# Terminal 1: Launch SketchUp
./03-launch-sketchup.sh

# Terminal 2: Monitor GPU usage
nvidia-smi dmon

# Terminal 3: Monitor CPU usage
top
```

---

## System Requirements Summary

| Component | Minimum | Recommended |
|-----------|---------|------------|
| RAM | 4GB | 8GB+ |
| Disk (prefix) | 500MB | 1GB+ |
| Disk (total with Wine) | 2GB | 3GB+ |
| GPU VRAM | 1GB | 2GB+ |
| Kernel | 4.19+ | 5.15+ |
| Mesa | 19.0+ | 21.0+ |

---

## Files in This Setup

```
sketchup-wine-setup/
├── scripts/
│   ├── 01-install-winehq.sh        # Install WineHQ stable
│   ├── 02-setup-wineprefix.sh      # Create prefix & dependencies
│   ├── 03-launch-sketchup.sh       # Launch SketchUp with GPU offloading
│   ├── 04-install-sketchup.sh      # Run SketchUp installer
│   └── README.md (this file)
├── config/
│   ├── wineprefix-registry.reg     # Optional: Pre-configured registry
│   └── user-settings.ini           # Optional: User preference templates
└── docs/
    ├── NVIDIA-GPU-OFFLOADING.md    # Detailed GPU offloading guide
    ├── WINETRICKS-COMPONENTS.md    # Component dependency list
    └── TROUBLESHOOTING.md          # Extended troubleshooting guide
```

---

## Additional Resources

- **WineHQ Official:** https://www.winehq.org/
- **Winetricks:** https://github.com/Winetricks/winetricks
- **DXVK:** https://github.com/doitsujin/dxvk
- **VKD3D:** https://github.com/lutris/vkd3d-proton
- **Trimble SketchUp:** https://www.sketchup.com/

---

## Support & Questions

If you encounter issues:

1. **Check this README** for your specific error
2. **Enable debug mode** in launch scripts (change `WINEDEBUG=-all` to `WINEDEBUG=+all`)
3. **Check Wine logs** in `~/.wine/sketchup2026/user.reg` and system logs
4. **Consult WineHQ forums:** https://forum.winehq.org/
5. **Community:** Linux Wine Gaming communities on Reddit, Discord

---

**Last Updated:** January 2026  
**Wine Version:** 10.0 or 9.0 (stable)  
**SketchUp Version:** 2026  
**System:** Fedora 42 + NVIDIA GTX 1050 Ti
