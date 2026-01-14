# Package Inventory & Download Guide

**For offline/VPN-restricted users who need all software in this repository.**

---

## 📦 What's Included in `packages/` Directory

### Current Status: Ready for Population

The directory structure is created and ready to receive packages:

```
packages/
├── tools/                          # Utilities & scripts
│   ├── winetricks                 # Main installation tool
│   └── rpmfusion-setup.txt        # Repository references
├── wine/                          # Wine RPM packages
│   └── [Wine RPMs for Fedora 42]
└── winetricks-components/         # Component caches
    ├── dotnet48/
    ├── vcrun2017/
    ├── webview2/
    ├── dxvk/
    └── vkd3d/
```

---

## 🔧 How to Populate Packages

### Method 1: Automatic Download (Requires Internet on Repository Machine)

Run the download script on a machine WITH internet access:

```bash
bash download-packages.sh
```

This will download:
- ✅ Winetricks script (~100 KB)
- ✅ Wine RPM packages (if available)
- ℹ️ Component references

Then copy the entire repository to your VPN-restricted machine.

### Method 2: Manual Download

Download files manually and place them in the correct directories:

**For `packages/tools/`:**
```bash
# Winetricks script
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks
mv winetricks packages/tools/
```

**For `packages/wine/`:**
```bash
# Wine for Fedora 42 (choose one)
wget https://dl.winehq.org/wine-builds/fedora/42/x86_64/wine-stable-10.0-1.fc42.x86_64.rpm
mv wine-stable-*.rpm packages/wine/

# Also get wine-common
wget https://dl.winehq.org/wine-builds/fedora/42/x86_64/wine-common-10.0-1.fc42.noarch.rpm
mv wine-common-*.rpm packages/wine/
```

### Method 3: Component Caching

Winetricks components (dotnet48, vcrun2017, webview2, etc.) are automatically downloaded and cached in `~/.cache/winetricks/` on first use.

To pre-populate `packages/winetricks-components/`:
```bash
# Run setup on a machine with internet
./scripts/00-master-setup-offline.sh

# Copy cache to packages/
cp -r ~/.cache/winetricks/* packages/winetricks-components/
```

---

## 📥 Required Software Packages

### Essential

| Component | Source | Size | Required |
|-----------|--------|------|----------|
| **Winetricks** | GitHub | 100 KB | ✅ Yes |
| **Wine** | WineHQ | 200-400 MB | ✅ Yes |
| **.NET Framework 4.8** | Microsoft (via winetricks) | 500-800 MB | ✅ Yes |
| **Visual C++ 2017** | Microsoft (via winetricks) | 100-150 MB | ✅ Yes |
| **WebView2** | Microsoft (via winetricks) | 1-2 GB | ✅ Yes |
| **DXVK** | GitHub (via winetricks) | 50-100 MB | ✅ Yes |
| **VKD3D** | GitHub (via winetricks) | 50-100 MB | ✅ Yes |

### Optional (System Dependencies)

| Package | Size | For |
|---------|------|-----|
| RPM Fusion Repos | Varies | Multimedia support |
| Vulkan drivers | 100-200 MB | Graphics acceleration |
| Pulseaudio | 1-2 MB | Audio support |

---

## 🔗 Download URLs

### Winetricks
- **GitHub:** https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
- **Size:** ~100 KB
- **Location:** `packages/tools/winetricks`

### Wine Stable for Fedora 42

**Latest Release:**
- https://dl.winehq.org/wine-builds/fedora/42/x86_64/wine-stable-10.0-1.fc42.x86_64.rpm
- https://dl.winehq.org/wine-builds/fedora/42/x86_64/wine-common-10.0-1.fc42.noarch.rpm

**Mirror Sites:**
- Mirror: `https://dl.winehq.org/wine-builds/fedora/42/`
- Size: 200-400 MB combined

**Location:** `packages/wine/`

### .NET Framework 4.8
- **Source:** Installed via winetricks automatically
- **Size:** 500-800 MB
- **Note:** Cannot be pre-downloaded, must be installed via winetricks on target machine
- **Location:** Auto-cached in `~/.cache/winetricks/` after first run

### WebView2 (Chromium-based)
- **Source:** Downloaded by winetricks
- **Size:** 1-2 GB (largest component)
- **Note:** This is the longest download during setup
- **Location:** Auto-cached in `~/.cache/winetricks/` after first run

### DXVK (DirectX via Vulkan)
- **Source:** GitHub releases or winetricks
- **Size:** 50-100 MB
- **GitHub:** https://github.com/doitsujin/dxvk/releases
- **Location:** Auto-installed by winetricks

### VKD3D (Direct3D 12)
- **Source:** GitHub releases or winetricks
- **Size:** 50-100 MB
- **GitHub:** https://github.com/HansKristian-Work/vkd3d-proton
- **Location:** Auto-installed by winetricks

---

## 📊 Total Disk Space Required

| Component | Size |
|-----------|------|
| Winetricks + scripts | 200 KB |
| Wine RPMs | 200-400 MB |
| Winetricks components | 2.5-3.5 GB |
| Repository overhead | 500 KB |
| **TOTAL** | **~2.7-3.9 GB** |

After installation on target machine: **~20-25 GB**

---

## ✅ Verification Checklist

After downloading packages, verify:

```bash
# Check directory structure
ls -R packages/

# Check winetricks is executable
file packages/tools/winetricks
stat packages/tools/winetricks

# Check Wine RPMs
ls -lh packages/wine/*.rpm

# Total size
du -sh packages/
```

---

## 🚀 Using Pre-Downloaded Packages

When you have all packages in `packages/`:

```bash
cd sketchup-wine-setup

# Use offline setup script
./scripts/00-master-setup-offline.sh

# This will:
# 1. Use local winetricks if available
# 2. Use local Wine RPMs if available
# 3. Download remaining components from system repos (minimal data)
# 4. Install everything needed
```

---

## 💡 Pro Tips for VPN Users

### Tip 1: Download on Alternative Machine
1. Clone repo on machine with full internet
2. Run `bash download-packages.sh`
3. Transfer via USB/cloud/email to VPN machine

### Tip 2: Staggered Downloads
1. First download Winetricks (~100 KB)
2. Run setup to identify what else is needed
3. Download additional packages as needed

### Tip 3: Offline Caching
1. Run setup once with minimal components
2. Copy auto-cached files from `~/.cache/winetricks/` to `packages/winetricks-components/`
3. Use those cached files for clean installs

### Tip 4: Configure DNF Proxy
If your machine has VPN CLI support:
```bash
# Edit /etc/dnf/dnf.conf
sudo nano /etc/dnf/dnf.conf

# Add lines:
# proxy=http://proxy.example.com:8080
# proxy_username=username
# proxy_password=password

# Then setup will work normally
```

---

## 🔄 Update Procedure

When Wine or components update:

1. **Check for new versions:**
   ```bash
   bash download-packages.sh
   ```

2. **Download new packages**

3. **Replace old packages in `packages/wine/`**

4. **Re-run setup:**
   ```bash
   ./scripts/00-master-setup-offline.sh
   ```

---

## ⚠️ Important Notes

1. **WebView2 is largest:** 1-2 GB, expect 5-15 minutes to download
2. **Components auto-cache:** Winetricks caches components in `~/.cache/winetricks/`
3. **First-time setup slower:** Subsequent installations use cached components
4. **RPMs are Fedora-specific:** Use correct Fedora version (42)
5. **Winetricks required:** The script file must be executable

---

## 📋 Download Status

| Component | Status | Size | Location |
|-----------|--------|------|----------|
| Winetricks | ✅ Ready | 100 KB | `packages/tools/` |
| Wine RPMs | ⏳ Optional | 200-400 MB | `packages/wine/` |
| Dotnet48 | ⏳ Auto-download | 500-800 MB | Auto-cached |
| VC++2017 | ⏳ Auto-download | 100-150 MB | Auto-cached |
| WebView2 | ⏳ Auto-download | 1-2 GB | Auto-cached |
| DXVK | ⏳ Auto-download | 50-100 MB | Auto-cached |
| VKD3D | ⏳ Auto-download | 50-100 MB | Auto-cached |

✅ = Ready in repository  
⏳ = Downloaded on-demand during setup

---

## 🎯 Next Steps

1. **For offline users:** Use `./scripts/00-master-setup-offline.sh`
2. **For normal users:** Use `./scripts/00-master-setup.sh`
3. **Both scripts use available local packages automatically**
4. **No configuration needed**

---

**Last Updated:** January 13, 2026  
**For:** Fedora 42 + NVIDIA GPU + VPN/Network Restrictions
