# Offline Installation Guide - IMPORTANT FOR VPN USERS

## 🔒 For Users Behind VPN/Network Restrictions

This guide explains how to use the **offline package** when you have limited network access or VPN that only works through browser.

---

## 📦 What's Included in This Repository

### Ready to Use
✅ All installation scripts  
✅ All documentation  
✅ Wine registry optimizations  
✅ GPU offloading configuration  
✅ Winetricks script (downloadable version)  

### Optional Local Packages
The `packages/` directory can contain:
- Wine RPM packages for Fedora 42
- Winetricks components cache
- Additional tools

**Note:** Large components (WebView2, .NET, etc.) are downloaded **on-demand** by Winetricks on your local machine, not pre-included.

---

## 🚀 Offline Setup Steps

### Step 1: Download Repository to Your Machine

**Option A: If you have internet on your machine**
```bash
git clone <repo-url>
cd HOLYFUCKINGWINE
```

**Option B: If downloading via VPN browser**
1. Download as ZIP from your browser
2. Extract on your Fedora 42 machine
3. Navigate to the directory

### Step 2: Check What's Included
```bash
ls -la packages/
```

Expected structure:
```
packages/
├── tools/           # Winetricks and utilities
├── wine/            # Wine RPM packages (if available)
└── winetricks-components/  # Component caches
```

### Step 3: Run Offline Setup
```bash
cd sketchup-wine-setup
chmod +x scripts/*.sh

# Run the OFFLINE setup script
./scripts/00-master-setup-offline.sh
```

This script will:
- ✅ Use local packages when available
- ✅ Download remaining components from system repos (if internet available on local machine)
- ✅ Use system package manager (dnf) for dependencies
- ✅ Install all Winetricks components

### Step 4: Install SketchUp
```bash
./scripts/04-install-sketchup.sh
```

### Step 5: Launch SketchUp
```bash
./scripts/03-launch-sketchup.sh
```

---

## 🌐 Internet Requirements

### During Setup
Your Fedora 42 machine needs **some internet access** for:
1. **First time only:** Downloading Winetricks components
   - .NET Framework 4.8
   - Visual C++ 2017 Runtime
   - WebView2 (largest, ~1-2 GB)
   - DXVK/VKD3D

2. **System dependencies** (if not already installed):
   - Wine libraries
   - Vulkan drivers
   - Multimedia support

### After Setup
✅ **No internet required** - SketchUp runs locally

### VPN Workaround
If your machine's internet ONLY works through VPN browser:

1. **Option A:** Manually download components on another machine with internet
   - Use the `download-packages.sh` script
   - Copy packages to this repo
   
2. **Option B:** Configure DNF to use proxy
   ```bash
   sudo dnf config-manager --save-config
   # Edit /etc/dnf/dnf.conf and set proxy
   ```

3. **Option C:** Use your browser to download packages
   - Files can be manually placed in `packages/` directory
   - Offline script will find and use them

---

## 📥 Pre-Downloading Components (Optional)

If you want to pre-download large components:

### On a Machine WITH Internet Access

```bash
# Clone this repository
git clone <repo-url>
cd HOLYFUCKINGWINE

# Run download manager
bash download-packages.sh

# This downloads:
# - Winetricks script
# - Wine RPM packages (if available)
# - References to other components

# Copy back to your machine with VPN
# Packages will be in ./packages/ directory
```

### What Gets Downloaded
- ✅ **Winetricks** (~100 KB) - Used for component installation
- ✅ **Wine RPM packages** (if available) - For offline Wine installation
- ℹ️ **Component references** - Links to official sources

---

## ⚡ Network-Specific Setup

### Scenario 1: Machine Behind VPN (No Direct Internet)
```bash
# Use system package manager with VPN
# Offline script handles this automatically
./scripts/00-master-setup-offline.sh
```

### Scenario 2: Machine Has Limited Internet
```bash
# Download during off-peak hours
# Or download on another machine and copy packages/
./scripts/00-master-setup-offline.sh
```

### Scenario 3: No Internet On Target Machine
```bash
# Pre-download everything on another machine
# 1. Run download-packages.sh on machine with internet
# 2. Copy entire repository to offline machine
# 3. Run offline setup script
./scripts/00-master-setup-offline.sh
```

---

## 📊 Bandwidth Requirements

### First-Time Setup Download Sizes

| Component | Size | Download Time |
|-----------|------|----------------|
| Wine | 200-400 MB | 1-3 min |
| .NET Framework 4.8 | 500-800 MB | 2-5 min |
| Visual C++ 2017 | 100-150 MB | 1-2 min |
| **WebView2** | **1-2 GB** | **5-15 min** |
| DXVK | 50-100 MB | <1 min |
| VKD3D | 50-100 MB | <1 min |
| **TOTAL** | **~2.5-3.5 GB** | **10-30 min** |

---

## 🔍 Troubleshooting Offline Setup

### "Can't download Winetricks components"
**Solution:** Ensure your machine has internet access during first setup. Components are downloaded on-demand.

### "Wine not found after setup"
**Check:**
```bash
wine --version
which wine
```

**Fix:**
```bash
# Wine may still be installing
sleep 30
wine --version

# Or install manually
sudo dnf install wine-stable
```

### "VPN only works through browser"
**Solutions:**
1. Temporarily disconnect VPN for setup
2. Use proxy configuration in DNF
3. Pre-download packages on machine with direct internet
4. Ask IT to allow CLI access to package managers

### "Offline script failing to find packages"
**Check:**
```bash
ls -R packages/

# Should show:
# packages/tools/winetricks
# packages/wine/*.rpm (if any)
```

**Fix:**
- Download packages on another machine
- Copy to `packages/` directory
- Ensure scripts are executable: `chmod +x scripts/*.sh`

---

## 📝 What to Download Manually (If Needed)

If the offline script can't get everything:

### Required Files
```
packages/
├── tools/
│   └── winetricks          (from GitHub)
├── wine/
│   └── *.rpm               (from WineHQ mirrors)
└── winetricks-components/
    ├── dotnet48/           (auto-cached by winetricks)
    ├── vcrun2017/          (auto-cached by winetricks)
    ├── webview2/           (auto-cached by winetricks)
    ├── dxvk/               (auto-cached by winetricks)
    └── vkd3d/              (auto-cached by winetricks)
```

### Download Sources

| Component | Source | Size |
|-----------|--------|------|
| Winetricks | https://github.com/Winetricks/winetricks | 100 KB |
| Wine RPM | https://dl.winehq.org/wine-builds/fedora/ | 200-400 MB |
| .NET 4.8 | Downloaded by winetricks on first run | 500-800 MB |
| WebView2 | Downloaded by winetricks on first run | 1-2 GB |
| DXVK | Downloaded by winetricks on first run | 100 MB |
| VKD3D | Downloaded by winetricks on first run | 100 MB |

---

## ✅ Offline Setup Complete

Once setup finishes:
- ✅ Wine configured
- ✅ All components installed
- ✅ GPU offloading ready
- ✅ SketchUp can be installed
- ✅ No more downloads needed

**SketchUp will run without any internet connection.**

---

## 🚀 Quick Reference

```bash
# 1. Extract/clone repository
tar xzf HOLYFUCKINGWINE.tar.gz
cd HOLYFUCKINGWINE

# 2. Make scripts executable
chmod +x sketchup-wine-setup/scripts/*.sh

# 3. Run offline setup (handles all options automatically)
sketchup-wine-setup/scripts/00-master-setup-offline.sh

# 4. Install SketchUp
sketchup-wine-setup/scripts/04-install-sketchup.sh

# 5. Launch SketchUp
sketchup-wine-setup/scripts/03-launch-sketchup.sh

# DONE! SketchUp is running with GPU support
```

---

## 📞 Still Having Issues?

1. **Check:** `sketchup-wine-setup/docs/TROUBLESHOOTING.md`
2. **Verify:** `sketchup-wine-setup/scripts/verify-setup.sh`
3. **Review:** `sketchup-wine-setup/docs/README.md`

All documentation is included in this repository - **no internet required to read it**.

---

**Last Updated:** January 13, 2026  
**For:** Fedora 42 + NVIDIA GPU + VPN/Network Restrictions
