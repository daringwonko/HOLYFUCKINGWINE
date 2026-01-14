# NVIDIA GPU Offloading Guide for SketchUp 2026

## Overview

Your Acer Nitro AN515-51 has **hybrid graphics** with:
- **Intel HD 630** (integrated, active by default on Wayland)
- **NVIDIA GeForce GTX 1050 Ti** (dedicated, much more powerful)

SketchUp 2026 requires **DirectX 12**, which performs poorly on Intel but excellently on NVIDIA.

This guide explains how GPU offloading works and how to verify it's active.

---

## How GPU Offloading Works

### NVIDIA PRIME Technology

NVIDIA PRIME (PowerRanging and Intelligent Mode Engine) allows selecting which GPU to use for rendering.

**For SketchUp, we use:**
```bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
```

### What These Variables Do

| Variable | Value | Effect |
|----------|-------|--------|
| `__NV_PRIME_RENDER_OFFLOAD` | `1` | Enables GPU offloading to NVIDIA |
| `__GLX_VENDOR_LIBRARY_NAME` | `nvidia` | Force OpenGL/Vulkan to use NVIDIA |
| `VK_LOADER_DEBUG` | `error` | Show only critical Vulkan errors |

### Alternative: Nvidia-persistenced

For persistent GPU usage:
```bash
sudo systemctl start nvidia-persistenced
sudo systemctl enable nvidia-persistenced
```

This keeps the NVIDIA GPU powered on and reduces startup latency.

---

## Verifying GPU Offloading is Active

### Method 1: Check with glxinfo

```bash
# With GPU offloading (should show NVIDIA)
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep "OpenGL renderer"
# Output: OpenGL renderer string: NVIDIA GeForce GTX 1050 Ti/PCIe/SSE2

# Without offloading (will show Intel)
glxinfo | grep "OpenGL renderer"
# Output: OpenGL renderer string: Mesa Intel(R) HD Graphics 630
```

### Method 2: Monitor NVIDIA GPU Usage

While SketchUp is running:

```bash
# Real-time GPU monitoring
nvidia-smi dmon

# Or watch GPU memory:
watch -n 1 nvidia-smi
```

**Expected output when SketchUp is running:**
```
 gpu   pwr gtemp mtemp    sm   mem   enc   dec  mclk  pclk
   0    25    35    40    40    45     0     0   405  1100
```

The `sm` (streaming multiprocessor) and `mem` (memory) columns should be non-zero.

### Method 3: Check Process Association

```bash
# Find SketchUp process
ps aux | grep -i wine | grep -i sketchup

# Check which GPU it's using (requires kernel module)
cat /sys/kernel/debug/dri/*/name
```

### Method 4: Performance Test in SketchUp

1. Open a large model in SketchUp (>10MB file)
2. Open System Monitor (GNOME, KDE, or `top`)
3. Expand the Wine process tree
4. Watch GPU usage:
   - **With offloading:** GPU load 30-80%, smooth panning
   - **Without offloading:** CPU load 80-100%, laggy panning

---

## Troubleshooting GPU Offloading

### GPU Not Being Used (Intel HD 630 Still Active)

**Symptoms:**
- SketchUp is very slow
- GPU usage is 0% (nvidia-smi shows no usage)
- High CPU usage instead

**Solutions:**

1. **Verify NVIDIA drivers are installed:**
   ```bash
   nvidia-smi
   # Should show driver version, GPU memory, and temperature
   ```

2. **Check if Wayland is using NVIDIA GPU:**
   ```bash
   echo $XDG_SESSION_TYPE
   # Should be "wayland" (not "x11")
   
   # Check which GPU Wayland is using:
   WAYLAND_DEBUG=protocol wayland-info 2>&1 | grep -i "render\|gpu"
   ```

3. **Force NVIDIA in launch script:**
   ```bash
   export __NV_PRIME_RENDER_OFFLOAD=1
   export __GLX_VENDOR_LIBRARY_NAME=nvidia
   export __NV_PREFER_SYS_LIBS=1  # Additional override
   wine "$SKETCHUP_EXE"
   ```

4. **Switch to X11 (if available):**
   ```bash
   # At login screen, select X11 session instead of Wayland
   # Then run SketchUp again
   ```

5. **Enable nvidia-persistenced (permanent GPU state):**
   ```bash
   sudo nvidia-smi -pm 1  # Enable persistence mode
   sudo systemctl start nvidia-persistenced
   ```

### GPU Crashes or Hangs When SketchUp Launches

**Symptoms:**
- Screen flickers or freezes
- GPU becomes unresponsive
- Device disappears from `nvidia-smi`

**Solutions:**

1. **Disable GPU persistence:**
   ```bash
   sudo nvidia-smi -pm 0
   sudo systemctl stop nvidia-persistenced
   ```

2. **Reduce GPU clock speeds:**
   ```bash
   sudo nvidia-smi -lgc 400,200  # Reduce to 400/200 MHz
   ```

3. **Reinstall NVIDIA drivers:**
   ```bash
   sudo dnf remove xorg-x11-drv-nvidia
   sudo dnf install xorg-x11-drv-nvidia
   sudo reboot
   ```

4. **Update DXVK/VKD3D:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   winetricks --self-update
   winetricks dxvk vkd3d --force
   ```

### Vulkan Not Working (VKD3D Error)

**Symptoms:**
- SketchUp crashes on startup
- Terminal shows: "Vulkan loader error" or "VK_ERROR_INCOMPATIBLE_DRIVER"

**Solutions:**

1. **Check Vulkan support:**
   ```bash
   vulkaninfo | grep "GPU" | head -5
   # Should show your GPU
   ```

2. **Update Vulkan libraries:**
   ```bash
   sudo dnf install vulkan-loader lib32-vulkan-loader
   ```

3. **Reinstall VKD3D:**
   ```bash
   export WINEPREFIX="$HOME/.wine/sketchup2026"
   winetricks vkd3d --force
   ```

4. **Verify 32-bit Vulkan:**
   ```bash
   ls /usr/lib*/libvulkan.so*
   # Should show 64-bit and 32-bit versions
   ```

---

## Power Management

### GPU Clock Speeds

Check current GPU speeds:
```bash
nvidia-smi -q | grep "Clocks"
```

### Dynamic Power Management

By default, NVIDIA GPU will power down when idle (saves battery on laptop).

To disable power management (keeps GPU always active):
```bash
sudo nvidia-smi -pm 1
```

To re-enable dynamic power management:
```bash
sudo nvidia-smi -pm 0
```

### Monitor Power Consumption

```bash
# Check power usage
nvidia-smi -q | grep "Power Consumption"

# Monitor in real-time
watch -n 1 'nvidia-smi -q | grep -A2 "Power Consumption"'
```

**Typical power draw:**
- Idle: 5-10W
- SketchUp idle: 10-15W
- SketchUp active: 25-40W
- SketchUp heavy model: 40-50W

---

## Performance Tuning

### Enable High Performance Mode

```bash
# Check current power setting
nvidia-smi -q | grep "Power State"

# Force maximum power mode (reduces latency)
sudo nvidia-smi -pm 1
```

### Reduce VSync Latency

In SketchUp Preferences:
1. Window > Preferences > OpenGL
2. Uncheck "Synchronize with monitor refresh"

### Override VK_PRESENT_MODE (Advanced)

```bash
export VK_PRESENT_MODE=mailbox  # Reduces input latency
./03-launch-sketchup.sh
```

---

## Energy Efficiency

For maximum battery life on your laptop:

```bash
#!/bin/bash
# Eco mode for battery operation
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Lower refresh rate to save power
export LIBGL_VSYNC_RATE=30  # 30 Hz instead of 60

# Use integrated GPU when not in SketchUp
sudo nvidia-smi -pm 0

wine "$SKETCHUP_EXE"
```

---

## Additional Notes

### Why Intel HD 630?

- Intel iGPU shares system memory (slower)
- No dedicated VRAM
- Lower performance on DirectX 12
- Default on Wayland (power saving)

### Why NVIDIA GTX 1050 Ti?

- 2GB dedicated VRAM
- 640 CUDA cores
- Excellent DirectX 12 support
- VKD3D support via Vulkan

### DirectX 12 Implementation Chain

```
SketchUp (D3D12 API)
    ↓
VKD3D (Translates D3D12 → Vulkan)
    ↓
DXVK (Handles D3D11, D3D10 fallbacks)
    ↓
Vulkan (GPU-agnostic graphics API)
    ↓
NVIDIA Driver (Vulkan → GPU)
    ↓
GTX 1050 Ti (Executes shaders)
```

---

## Quick Reference Commands

```bash
# Verify offloading is working
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep renderer

# Check GPU temperature while SketchUp runs
nvidia-smi -q -d TEMPERATURE

# Monitor all GPU stats
nvidia-smi dmon

# List installed GPU drivers
dnf list installed | grep nvidia

# Check Vulkan layers
vulkaninfo --summary

# Enable GPU persistence
sudo nvidia-smi -pm 1

# Show GPU power limits
nvidia-smi -q | grep -A5 "Power Limits"
```

---

**Last Updated:** January 2026  
**System:** Fedora 42 + NVIDIA GTX 1050 Ti + Intel HD 630
