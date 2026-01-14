# Extended Troubleshooting Guide - SketchUp 2026 on Wine

---

## Table of Contents

1. [Installation Phase Issues](#installation-phase-issues)
2. [Launch Phase Issues](#launch-phase-issues)
3. [Runtime Issues](#runtime-issues)
4. [Login & Authentication](#login--authentication)
5. [Graphics & Rendering](#graphics--rendering)
6. [Performance Issues](#performance-issues)
7. [Data Corruption & Recovery](#data-corruption--recovery)

---

## Installation Phase Issues

### Problem: WineHQ Repository Installation Fails

**Symptom:**
```
Error: Failed to add repository
Unable to download from dl.winehq.org
Connection refused
```

**Causes:**
- Network connectivity issue
- Repository server down
- Firewall blocking access

**Solutions:**

1. **Check internet connection:**
   ```bash
   ping -c 3 8.8.8.8
   ```

2. **Try alternative repository (from Fedora COPR):**
   ```bash
   sudo dnf copr enable sentry/wine
   sudo dnf install wine
   ```

3. **Use Flatpak/Bottles as fallback:**
   ```bash
   flatpak install flathub com.usebottles.bottles
   # Then use Bottles GUI to create a Wine runner
   ```

4. **Manual Wine installation:**
   ```bash
   # Build from source (advanced)
   git clone https://github.com/wine-mirror/wine.git
   cd wine
   ./configure --enable-win64
   make -j$(nproc)
   sudo make install
   ```

---

### Problem: Insufficient Disk Space

**Symptom:**
```
Error: No space left on device
Installation failed at XX%
```

**Solutions:**

1. **Check available space:**
   ```bash
   df -h ~
   # Look for available space in home partition
   ```

2. **Free up space:**
   ```bash
   # Remove old packages
   sudo dnf clean all
   
   # Remove old logs
   journalctl --vacuum=2weeks
   
   # Check large files
   du -sh ~/* | sort -hr | head -10
   ```

3. **Use external drive (if main drive is full):**
   ```bash
   # Create prefix on external drive
   export WINEPREFIX="/mnt/external/sketchup2026"
   ./02-setup-wineprefix.sh
   ```

---

### Problem: Winetricks Hangs on Specific Component

**Symptom:**
```
winetricks webview2
[Installation progress bar freezes at X%]
[No CPU activity, no disk activity for >5 minutes]
```

**Most Common:** webview2 is known to hang (can take 15-20 minutes on slow systems)

**Solutions:**

1. **Wait patiently (seriously!):**
   - webview2 is 400MB and can take 20 minutes on slow networks/systems
   - Monitor system resources in another terminal:
     ```bash
     watch -n 1 "ps aux | grep wine; echo '---'; df -h"
     ```

2. **If truly frozen (no activity for 30+ minutes):**
   ```bash
   # Kill the hanging process
   killall -9 wine wineserver
   sleep 3
   
   # Clean up incomplete installation
   rm -rf ~/.wine/sketchup2026/drive_c/Program\ Files/SketchUp/
   rm -rf ~/.wine/sketchup2026/drive_c/windows/system32/webview2
   
   # Try again
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   winetricks webview2 --force
   ```

3. **Skip and retry later (risky):**
   ```bash
   # Install other components first
   winetricks dotnet48 vcrun2017 dxvk vkd3d
   
   # Retry webview2 separately
   winetricks webview2 --force
   ```

---

### Problem: Wine Directory Already Exists

**Symptom:**
```
Error: ~/.wine/sketchup2026 already exists
wineboot: failed to initialize wineprefix
```

**Solutions:**

1. **Use existing prefix (if it's good):**
   ```bash
   # If the existing prefix is functional, just use it
   # Check if it's valid:
   file ~/.wine/sketchup2026/system.reg
   # Should return: "data" (registry file)
   ```

2. **Delete and recreate:**
   ```bash
   rm -rf ~/.wine/sketchup2026/
   ./02-setup-wineprefix.sh
   ```

3. **Use different prefix name:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026-new"
   ./02-setup-wineprefix.sh
   ```

---

## Launch Phase Issues

### Problem: Wine Command Not Found

**Symptom:**
```
./03-launch-sketchup.sh: wine: command not found
```

**Causes:**
- Wine not installed
- Wine not in PATH
- Wrong Wine version

**Solutions:**

1. **Verify wine is installed:**
   ```bash
   which wine
   # Should show: /usr/bin/wine or similar
   
   # If not found, reinstall:
   sudo dnf install winehq-stable
   ```

2. **Check wine version:**
   ```bash
   wine --version
   # Should show: Wine 10.0 or Wine 9.0
   ```

3. **Use full path to wine:**
   ```bash
   # Find wine location
   find /usr -name wine -type f 2>/dev/null
   
   # Edit scripts to use full path:
   /usr/bin/wine "$SKETCHUP_EXE"
   ```

---

### Problem: "Bad EXE Format" Error

**Symptom:**
```
wine: Bad EXE format for [.../SketchUp.exe].
```

**Causes:**
- Wrong architecture (32-bit EXE on 64-bit only prefix)
- Corrupted EXE file
- Wrong file format

**Solutions:**

1. **Verify EXE file:**
   ```bash
   file /home/tomas/SketchUp\ 2026/SketchUp.exe
   # Should show: PE32+ executable (x86-64) or similar
   ```

2. **Check WINEARCH:**
   ```bash
   echo $WINEARCH
   # Should be: win64 (for 64-bit SketchUp)
   ```

3. **Verify EXE isn't corrupted:**
   ```bash
   md5sum /home/tomas/SketchUp\ 2026/SketchUp.exe
   # Compare with official SketchUp's MD5 hash
   ```

4. **If file is corrupted, re-download SketchUp**

---

### Problem: Wine Crashes Immediately on Launch

**Symptom:**
```
wine: Segmentation fault
[No error message, instant crash]
```

**Causes:**
- Missing dependencies
- Incompatible Wine version
- Corrupted prefix

**Solutions:**

1. **Enable debug output:**
   ```bash
   export WINEDEBUG=+all
   ./03-launch-sketchup.sh 2>&1 | tail -50
   ```

2. **Verify all components are installed:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   winetricks list-installed
   # Should show: dotnet48, vcrun2017, webview2, dxvk, vkd3d
   ```

3. **Reinstall missing components:**
   ```bash
   ./02-setup-wineprefix.sh
   ```

4. **Try running simple executable:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   wine cmd /c echo "test"
   # If this works, Wine is functional
   ```

---

## Runtime Issues

### Problem: SketchUp Starts but Immediately Closes

**Symptom:**
```
./03-launch-sketchup.sh
[SketchUp window appears briefly, then closes]
[No error message]
```

**Causes:**
- Missing runtime library
- Trimble Identity login fails
- GPU crash (less likely)

**Solutions:**

1. **Check Wine error log:**
   ```bash
   tail -100 ~/.wine/sketchup2026/user.reg
   # Look for error entries
   ```

2. **Verify dotnet48 is working:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   wine reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\.NETFramework" | head -5
   ```

3. **Verify vcrun2017:**
   ```bash
   ls ~/.wine/sketchup2026/drive_c/Windows/System32/vcruntime140.dll
   # Should exist
   ```

4. **Reinstall .NET and C++ runtime:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   winetricks dotnet48 vcrun2017 --force
   ```

5. **Try with debug output:**
   ```bash
   export WINEDEBUG=+all
   ./03-launch-sketchup.sh 2>&1 | grep -i "error\|fail\|missing" | head -20
   ```

---

### Problem: SketchUp Opens but Login Screen Won't Display

**Symptom:**
```
SketchUp window appears
[Blank white window]
[Trimble Identity login screen doesn't appear]
```

**Causes:**
- WebView2 not installed or corrupted
- Network connectivity issue
- Chromium/WebView2 rendering problem

**Solutions:**

1. **Verify WebView2 installation:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   winetricks list-installed | grep webview2
   ```

2. **Reinstall WebView2:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   rm -rf drive_c/windows/system32/webview2
   winetricks webview2 --force
   # This will take 10-15 minutes
   ```

3. **Check network from within Wine:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   wine cmd /c nslookup trimble.com
   # Should resolve to IP address
   ```

4. **Check if Trimble servers are accessible:**
   ```bash
   curl -I https://identity.sketchup.com/
   # Should return HTTP 200 or 3xx
   ```

---

## Login & Authentication

### Problem: Trimble Identity Login Times Out

**Symptom:**
```
Login screen appears
[Entering credentials]
Error: "Login timed out" or "Connection timeout"
```

**Causes:**
- Network latency (Wine's network slower)
- Trimble server temporary outage
- WebView2 networking issue

**Solutions:**

1. **Try again (server might be temporary issue)**

2. **Check your internet connection:**
   ```bash
   ping -c 5 trimble.com
   # Should get responses with <100ms latency
   ```

3. **Ensure DNS works:**
   ```bash
   nslookup identity.sketchup.com
   # Should resolve properly
   ```

4. **Try offline mode (if available):**
   - In SketchUp, check for "Work Offline" or "Skip Login"

5. **Test network from Wine:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   wine powershell -Command "Invoke-WebRequest -Uri 'https://identity.sketchup.com/' -UseBasicParsing"
   ```

---

### Problem: 2FA (Two-Factor Authentication) Won't Work

**Symptom:**
```
Login works
2FA code input appears
[Code is entered]
Error: "Invalid code" or code times out
```

**Causes:**
- System time skew (OTP codes time-dependent)
- Trimble doesn't recognize device
- WebView2 session issue

**Solutions:**

1. **Synchronize system time:**
   ```bash
   # Check current time
   date
   
   # Synchronize with NTP
   sudo chronyc -a makestep
   # Or:
   sudo systemctl restart chronyd
   ```

2. **Trust device on next login:**
   - When 2FA prompts, check "Trust this device for 30 days"

3. **Use backup codes:**
   - Log into Trimble account from browser
   - Generate and save backup 2FA codes
   - Use backup code if app codes don't work

4. **Clear WebView2 cache:**
   ```bash
   rm -rf ~/.wine/sketchup2026/drive_c/Program\ Files/SketchUp/*/INetCache/
   ```

---

## Graphics & Rendering

### Problem: SketchUp Graphics Corrupted (Flickering, Distorted)

**Symptom:**
```
SketchUp opens
Models display with visual artifacts
Triangles, flickering, distorted geometry
```

**Causes:**
- DXVK/VKD3D incompatibility
- GPU memory corruption
- Vulkan shader compilation error

**Solutions:**

1. **Update graphics drivers:**
   ```bash
   # NVIDIA drivers
   sudo dnf update xorg-x11-drv-nvidia
   
   # DXVK/VKD3D
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   winetricks dxvk vkd3d --force
   ```

2. **Enable DXVK debug logging:**
   ```bash
   export DXVK_LOG_LEVEL=debug
   export DXVK_LOG_PATH=$HOME/dxvk-debug.log
   ./03-launch-sketchup.sh
   
   # Check log
   cat ~/dxvk-debug.log | tail -50
   ```

3. **Try DXVK without async compilation:**
   ```bash
   export DXVK_ASYNC=0
   ./03-launch-sketchup.sh
   ```

4. **Disable GPU offloading temporarily (debug):**
   ```bash
   # Run on Intel GPU to isolate issue
   unset __NV_PRIME_RENDER_OFFLOAD
   unset __GLX_VENDOR_LIBRARY_NAME
   ./03-launch-sketchup.sh
   
   # If Intel works, issue is NVIDIA-specific
   ```

---

### Problem: "GL Error" or Vulkan Error on Launch

**Symptom:**
```
wine: Call from ... (tid 0x...) unimplemented function vulkan.dll.something
VkError: VK_ERROR_INCOMPATIBLE_DRIVER
```

**Causes:**
- Vulkan driver not properly installed
- Vulkan libraries are 64-bit only (missing 32-bit)
- VKD3D incompatible with GPU driver

**Solutions:**

1. **Install 32-bit Vulkan libraries:**
   ```bash
   sudo dnf install lib32-vulkan-loader lib32-libxcb lib32-libxkbcommon
   ```

2. **Verify Vulkan support:**
   ```bash
   vulkaninfo | grep "GPU"
   # Should show your GPU
   
   # Check 32-bit support:
   ls /usr/lib*/libvulkan.so*
   ```

3. **Update Vulkan loader:**
   ```bash
   sudo dnf update vulkan-loader lib32-vulkan-loader
   ```

4. **Reinstall DXVK/VKD3D:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   winetricks dxvk vkd3d --force
   ```

---

## Performance Issues

### Problem: SketchUp Very Slow / Laggy

**Symptom:**
```
Model rotation is slow
Panning is sluggish
High latency when clicking
```

**Causes:**
- GPU offloading not working (using Intel instead)
- GPU memory pressure
- Shader compilation ongoing
- Wayland input latency

**Solutions:**

1. **Verify GPU offloading is active:**
   ```bash
   __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep "OpenGL renderer"
   # Should show: NVIDIA GeForce GTX 1050 Ti
   ```

2. **Monitor GPU usage while running:**
   ```bash
   # Terminal 1: SketchUp
   ./03-launch-sketchup.sh
   
   # Terminal 2: Monitor
   nvidia-smi dmon
   # Look at 'sm' (streaming multiprocessor) and 'mem' columns
   # If both are 0%, GPU isn't being used
   ```

3. **Check for shader compilation:**
   - First load of a scene with new shaders takes time
   - Subsequent loads should be fast
   - If always slow, issue is not shader compilation

4. **Try reducing rendering quality:**
   - In SketchUp Preferences > OpenGL
   - Reduce shadow quality, reflection quality

5. **Switch to X11 display server (if on Wayland):**
   ```bash
   # At login screen, select "GNOME on Xorg" instead of "GNOME"
   # Then restart SketchUp
   ```

---

### Problem: GPU Usage is 0%, Using Intel Instead

**Symptom:**
```
nvidia-smi shows no usage
gpu memory: 0 MB / 2048 MB used
OpenGL renderer shows "Intel"
```

**Causes:**
- `__NV_PRIME_RENDER_OFFLOAD` not set correctly
- Wine not inheriting environment variables
- NVIDIA driver not properly initialized

**Solutions:**

1. **Verify variables are set in script:**
   ```bash
   # Edit 03-launch-sketchup.sh
   # Add this after environment variable section:
   echo "Environment Variables:"
   echo "__NV_PRIME_RENDER_OFFLOAD=$__NV_PRIME_RENDER_OFFLOAD"
   echo "__GLX_VENDOR_LIBRARY_NAME=$__GLX_VENDOR_LIBRARY_NAME"
   
   # Run script
   ./03-launch-sketchup.sh
   # Should print the values before launch
   ```

2. **Ensure persistent GPU mode is enabled:**
   ```bash
   sudo nvidia-smi -pm 1
   ```

3. **Enable GPU persistence:**
   ```bash
   sudo systemctl start nvidia-persistenced
   sudo systemctl enable nvidia-persistenced
   ```

4. **Try alternative environment variables:**
   ```bash
   export LIBGL_DRIVER_PATH=/usr/lib64/dri
   export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH
   export __NV_PRIME_RENDER_OFFLOAD=1
   export __GLX_VENDOR_LIBRARY_NAME=nvidia
   ./03-launch-sketchup.sh
   ```

---

### Problem: Model Takes Extremely Long to Load

**Symptom:**
```
[Load Model dialog shows 0% for >30 seconds]
[Then suddenly completes]
[Subsequent loads are faster]
```

**This is NORMAL** for first load with VKD3D shader compilation.

**Solutions:**

1. **Let it finish (don't interrupt)**
   - First scene load: 30-60 seconds
   - Shader compilation is happening in background

2. **Monitor compilation progress:**
   ```bash
   export DXVK_LOG_LEVEL=info
   ./03-launch-sketchup.sh 2>&1 | grep -i "shader\|compile"
   ```

3. **Optimize for future loads:**
   - Pre-load commonly-used models to compile their shaders
   - VKD3D caches compiled shaders

---

## Data Corruption & Recovery

### Problem: Wine Prefix is Corrupted

**Symptom:**
```
Registry errors
DLL files missing
Crashes with cryptic errors
```

**Solutions:**

1. **Backup and rebuild:**
   ```bash
   # Backup existing prefix
   tar -czf sketchup2026-corrupt-backup.tar.gz ~/.wine/sketchup2026/
   
   # Remove corrupted prefix
   rm -rf ~/.wine/sketchup2026/
   
   # Rebuild from scratch
   ./02-setup-wineprefix.sh
   ```

2. **Repair registry:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   wineboot -r  # Restart Wine to repair registry
   ```

3. **Check disk for bad sectors:**
   ```bash
   # If corruption is filesystem-related
   sudo badblocks -v /dev/sdXY  # Replace sdXY with your partition
   ```

---

### Problem: SketchUp Files Lost from Wine Prefix

**Symptom:**
```
Previously installed SketchUp is gone
All files in Program Files/SketchUp/ deleted
```

**Causes:**
- Accidental deletion
- Prefix was reset
- Windows updater cleared old files

**Solutions:**

1. **Check if files are in trash:**
   ```bash
   ls ~/.local/share/Trash/files/ | grep -i sketch
   ```

2. **Restore from backup (if you made one):**
   ```bash
   tar -xzf sketchup2026-prefix-backup.tar.gz -C ~/
   ```

3. **Reinstall SketchUp:**
   ```bash
   ./04-install-sketchup.sh
   ```

4. **Recover from system trash:**
   ```bash
   # If recently deleted
   find ~/.local/share/Trash -name "*SketchUp*" -o -name "*.skp"
   ```

---

## Emergency Recovery

### Complete Prefix Reset

```bash
#!/bin/bash
# Complete reset - use only if absolutely necessary

echo "WARNING: This will DELETE ~/.wine/sketchup2026 completely"
read -p "Type 'YES' to confirm: " confirm

if [ "$confirm" = "YES" ]; then
    # Kill all Wine processes
    killall -9 wine wineserver 2>/dev/null || true
    sleep 2
    
    # Remove entire prefix
    rm -rf ~/.wine/sketchup2026/
    
    # Rebuild
    export WINEPREFIX="$HOME/.wine/sketchup2026"
    ./02-setup-wineprefix.sh
    
    echo "Prefix reset complete. Reinstall SketchUp if needed."
else
    echo "Cancelled"
fi
```

---

### Log Collection for Support

If you need to ask for help, collect these logs:

```bash
#!/bin/bash
# Collect debugging information

mkdir -p ~/sketchup-debug-logs
cd ~/sketchup-debug-logs

# Wine/System info
echo "=== System Info ===" > system-info.txt
uname -a >> system-info.txt
dnf list installed | grep -E "wine|nvidia|vulkan" >> system-info.txt

# Wine version
wine --version > wine-version.txt

# GPU info
nvidia-smi > nvidia-info.txt
vulkaninfo --summary > vulkan-info.txt

# Wine logs
cp ~/.wine/sketchup2026/user.reg sketchup2026-user.reg

# Run SketchUp with debug
WINEDEBUG=+all wine /path/to/SketchUp.exe 2>&1 | head -1000 > sketchup-debug.log

# Create archive
tar -czf sketchup-debug-logs.tar.gz *.txt *.log *.reg

echo "Debug logs collected to: ~/sketchup-debug-logs.tar.gz"
```

Then share the `sketchup-debug-logs.tar.gz` file with support.

---

**Last Updated:** January 2026
