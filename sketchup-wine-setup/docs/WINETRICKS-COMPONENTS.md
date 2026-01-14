# Winetricks Components for SketchUp 2026

This document details each winetricks component installed for SketchUp 2026 and why it's required.

---

## Installed Components Summary

| Component | Version | Category | Status | Purpose |
|-----------|---------|----------|--------|---------|
| `dotnet48` | 4.8 | Runtime | REQUIRED | .NET Framework core |
| `vcrun2017` | 2017 | Runtime | REQUIRED | Visual C++ runtime |
| `webview2` | Latest | Browser | CRITICAL | Trimble Identity login |
| `dxvk` | Latest | Graphics | REQUIRED | DirectX 10/11/12 |
| `vkd3d` | Latest | Graphics | REQUIRED | D3D12 compilation |
| `winver=win10` | 10 | OS Config | REQUIRED | Windows 10 compatibility |

---

## Detailed Component Documentation

### 1. dotnet48 - .NET Framework 4.8

**What it is:**
- Microsoft .NET Framework 4.8 runtime
- Allows applications using .NET to run

**Why SketchUp needs it:**
- SketchUp 2026 core application uses .NET 4.8
- Required for initialization and plugins
- Without it: SketchUp will fail to launch with "Missing .NET Framework" error

**Installation:**
```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks dotnet48
```

**Size:** ~200MB on disk
**Duration:** 3-5 minutes
**Verification:**
```bash
ls ~/.wine/sketchup2026/drive_c/Windows/Microsoft.NET/Framework64/v4.0.30319/
# Should show: mscorlib.dll, System.dll, etc.
```

**Potential Issues:**
- Installation timeout: Run again, it will continue
- "Wine looks too old": Ensure Wine 9.0+ is installed
- Memory errors: Close other applications, increase swap

---

### 2. vcrun2017 - Visual C++ 2017 Runtime

**What it is:**
- Microsoft Visual C++ 2017 runtime libraries
- Required by native C++ code

**Why SketchUp needs it:**
- SketchUp uses C++ modules for 3D rendering
- Provides MSVCP140.dll, VCRUNTIME140.dll
- Without it: DLL load errors on startup

**Installation:**
```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks vcrun2017
```

**Size:** ~150MB on disk
**Duration:** 2-3 minutes

**Verification:**
```bash
ls ~/.wine/sketchup2026/drive_c/Windows/System32/ | grep -i vcrun
# Should show: vcruntime140.dll, msvcp140.dll
```

**Related Runtimes (if needed):**
```bash
# Earlier versions (not typically needed):
winetricks vcrun2015  # Visual C++ 2015
winetricks vcrun2013  # Visual C++ 2013

# Later versions (for compatibility):
winetricks vcrun2019  # Visual C++ 2019
```

---

### 3. webview2 - WebView2 Runtime (CRITICAL)

**What it is:**
- Microsoft Edge WebView2 browser component
- Embedded Chromium for modern web rendering

**Why SketchUp CRITICALLY needs it:**
- **Trimble Identity login screen** is built on WebView2
- This is the **ONLY way to authenticate** with Trimble account
- Without it: Login screen won't render, app is completely unusable
- Required for Trimble Sync and cloud features

**Installation:**
```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks webview2
```

**Size:** ~400MB on disk
**Duration:** 8-12 minutes (longest component)
**The component appears to hang - this is NORMAL. Do NOT interrupt.**

**Verification:**
```bash
ls -lh ~/.wine/sketchup2026/drive_c/Program\ Files/SketchUp/
# If SketchUp is installed, you'll see it here

# Or check in registry:
wine reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\EdgeUpdate" 2>/dev/null
```

**Troubleshooting WebView2 Hangs:**
```bash
# If installation appears stuck for >15 minutes:
ps aux | grep -i webview
# If process is still running, wait more (can take 20 min on slow systems)

# If truly frozen:
killall wineserver
sleep 3
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks webview2 --force
```

**Trimble Identity Technical Details:**
- Login form: HTML/JavaScript rendered by WebView2
- Authentication: OAuth2 via Trimble servers
- Two-factor auth: Supported through WebView2
- Session storage: In Wine prefix

---

### 4. dxvk - Direct3D Implementation via Vulkan

**What it is:**
- Direct3D 11/10/9c translation layer
- Converts DirectX calls to Vulkan
- High performance on modern GPUs

**Why SketchUp needs it:**
- SketchUp uses Direct3D for 3D rendering
- DXVK provides excellent performance on NVIDIA
- Fallback for D3D11/10 when VKD3D isn't suitable
- Handles advanced graphics features

**Installation:**
```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks dxvk
```

**Size:** ~50MB on disk
**Duration:** 1-2 minutes

**Rendering Pipeline:**
```
SketchUp 3D Graphics
    ↓
Direct3D 11 API calls
    ↓
DXVK (D3D→Vulkan translation)
    ↓
Vulkan API
    ↓
NVIDIA Driver
    ↓
GTX 1050 Ti GPU
```

**Performance Notes:**
- DXVK is faster than native D3D on Wine
- Requires Vulkan-capable GPU (all modern GPUs support it)
- On NVIDIA: Uses proprietary Vulkan driver

**Verification:**
```bash
# Check if DXVK is properly set up
export WINEPREFIX="$HOME/.wine/sketchup2026"
ls -la drive_c/windows/system32/d3d*.dll | head -5

# Check Vulkan support
vulkaninfo | grep "GPU"
```

---

### 5. vkd3d - Direct3D 12 via Vulkan

**What it is:**
- Direct3D 12 implementation using Vulkan
- Lower-level GPU access than D3D11
- Modern graphics API translation

**Why SketchUp 2026 needs it:**
- SketchUp 2026 uses **new graphics engine** with D3D12
- D3D12 provides better performance on modern GPUs
- Shader model 5.1+ support via Vulkan
- GPU multithreading improvements

**Installation:**
```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks vkd3d
```

**Size:** ~30MB on disk
**Duration:** 1-2 minutes

**Rendering Pipeline (Modern):**
```
SketchUp 2026 (D3D12 graphics engine)
    ↓
Direct3D 12 API calls
    ↓
VKD3D (D3D12→Vulkan translation)
    ↓
Vulkan API
    ↓
NVIDIA Driver + GTX 1050 Ti
    ↓
Shader compilation → GPU execution
```

**Shader Compilation:**
- First launch may take 30-60 seconds
- VKD3D compiles D3D12 shaders to Vulkan SPIR-V
- Compiled shaders are cached for future launches
- Subsequent launches are much faster

**Performance Benefits:**
- Reduced driver overhead vs D3D11
- Better GPU utilization on multi-core systems
- Improved model rotation/panning responsiveness

**Verification:**
```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks list-installed | grep vkd3d
# Should show: vkd3d is installed
```

---

### 6. winver=win10 - Windows Version Setting

**What it is:**
- Tells Wine to report Windows 10 as the running OS
- Affects OS detection by applications

**Why SketchUp needs it:**
- SketchUp 2026 optimizes for Windows 10+
- Some features only work on Win10+
- Ensures compatibility with modern libraries

**Installation:**
```bash
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks winver win10
```

**Size:** No additional download
**Duration:** Instant

**Registry Impact:**
```
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion
    CurrentVersion = 10.0  # Windows 10
    ProductName = Windows 10
```

**Other Options:**
```bash
winetricks winver win11    # Windows 11 (not recommended, may break compat)
winetricks winver win7     # Windows 7 (too old for SketchUp 2026)
```

---

## Installation Order & Dependencies

### Recommended Order (What 02-setup-wineprefix.sh does):

1. **winver=win10** → Set OS version (instant)
2. **dotnet48** → .NET Framework core (needed by most)
3. **vcrun2017** → C++ runtime (needed by most)
4. **webview2** → Browser component (slowest, install first of graphics)
5. **dxvk** → D3D translation (10/11 fallback)
6. **vkd3d** → D3D12 translation (primary graphics)

### Why This Order?

- dotnet48 and vcrun2017 must come **before** webview2 (dependencies)
- webview2 **blocks** other installations, so do it early
- dxvk before vkd3d (dxvk may configure some D3D paths)

### Alternative Order (If One Fails):

```bash
# Try individual installations
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks winver=win10
winetricks dotnet48 --force
winetricks vcrun2017 --force
winetricks dxvk --force
winetricks vkd3d --force
winetricks webview2 --force
```

The `--force` flag will override any existing installation.

---

## Disk Space Requirements

Total disk space needed in `~/.wine/sketchup2026/`:

```
Base Wine prefix:           100MB
dotnet48:                   200MB
vcrun2017:                  150MB
webview2:                   400MB
dxvk:                        50MB
vkd3d:                       30MB
SketchUp 2026 (if installed): 1.2GB
─────────────────────────────────
TOTAL:                   ~2.1GB (without SketchUp)
                         ~3.3GB (with SketchUp)
```

---

## Verification Script

```bash
#!/bin/bash
# Verify all components are installed

export WINEPREFIX="$HOME/.wine/sketchup2026"

echo "=== Winetricks Component Verification ==="
echo ""

echo "Windows Version:"
winetricks winver
echo ""

echo "Installed Components:"
winetricks list-installed | grep -E "dotnet48|vcrun2017|webview2|dxvk|vkd3d"
echo ""

echo "File Checks:"
echo -n "dotnet48: "
[ -f "$WINEPREFIX/drive_c/Windows/Microsoft.NET/Framework64/v4.0.30319/mscorlib.dll" ] && echo "✓" || echo "✗"

echo -n "vcrun2017: "
[ -f "$WINEPREFIX/drive_c/Windows/System32/vcruntime140.dll" ] && echo "✓" || echo "✗"

echo -n "webview2: "
[ -d "$WINEPREFIX/drive_c/Program Files/SketchUp" ] || [ -d "$WINEPREFIX/drive_c/windows/system32/webview2" ] && echo "✓" || echo "✗"

echo -n "dxvk: "
[ -f "$WINEPREFIX/drive_c/windows/system32/d3d11.dll" ] && echo "✓" || echo "✗"

echo -n "vkd3d: "
[ -f "$WINEPREFIX/drive_c/windows/system32/d3d12.dll" ] && echo "✓" || echo "✗"

echo ""
echo "Vulkan Support:"
vulkaninfo --summary 2>/dev/null | head -3 || echo "Vulkan not available"
```

---

## Troubleshooting Specific Components

### dotnet48 fails

```bash
# Check if already installed
wine reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\.NETFramework" /s

# Reinstall
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks dotnet48 --force

# Alternative (if winetricks fails):
# Download installer manually and run:
wine dotnet.exe /quiet /install
```

### vcrun2017 fails

```bash
# Check installed runtimes
ls ~/.wine/sketchup2026/drive_c/Windows/System32/*vcrun*.dll

# Reinstall
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks vcrun2017 --force
```

### webview2 appears hung

```bash
# Normal behavior: takes 8-15 minutes
# Check if still running:
ps aux | grep -E "wine|webview|msiexec"

# If it's truly hung (no process and no progress):
killall wineserver
rm -rf ~/.wine/sketchup2026/drive_c/Program\ Files/SketchUp
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks webview2 --force
```

### DXVK fails

```bash
# Check Vulkan
vulkaninfo | grep "GPU"  # Should show GPU

# Update Vulkan libraries
sudo dnf install vulkan-loader lib32-vulkan-loader

# Reinstall DXVK
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks dxvk --force
```

### VKD3D fails

```bash
# Same as DXVK - usually Vulkan-related
vulkaninfo --summary

# Update and reinstall
sudo dnf install vulkan-loader lib32-vulkan-loader
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks vkd3d --force
```

---

## Advanced: Manual Component Installation

If winetricks fails, you can install components manually:

### Manual dotnet48

```bash
# Download installer
wget https://dotnetcli.blob.core.windows.net/dotnet/release/net4.8/4.8/dotnet-framework-48-runtime-installer.exe

# Install via Wine
export WINEPREFIX="$HOME/.wine/sketchup2026"
wine dotnet-framework-48-runtime-installer.exe /quiet /install
```

### Manual DXVK

```bash
# Download DXVK
wget https://github.com/doitsujin/dxvk/releases/download/v1.10.3/dxvk-1.10.3.tar.gz

# Extract and install
tar xzf dxvk-1.10.3.tar.gz
cd dxvk-1.10.3
export WINEPREFIX="$HOME/.wine/sketchup2026"
./setup_dxvk.sh install
```

---

**Last Updated:** January 2026  
**SketchUp Version:** 2026  
**Wine Version:** 10.0/9.0 stable
