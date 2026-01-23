# Complete GPU Passthrough (VFIO) Guide

## For: Acer Nitro AN515-51 (Intel HD 630 + NVIDIA GTX 1050 Ti)

This guide covers passing your NVIDIA GTX 1050 Ti (4GB VRAM) to a Windows VM while keeping the Intel HD 630 for your Linux host. When done correctly, the Windows VM will have full, bare-metal GPU performance.

---

## Table of Contents

1. [Understanding GPU Passthrough](#understanding-gpu-passthrough)
2. [Hardware Requirements Check](#hardware-requirements-check)
3. [BIOS Configuration](#bios-configuration)
4. [Kernel Configuration](#kernel-configuration)
5. [IOMMU Group Analysis](#iommu-group-analysis)
6. [Isolating the NVIDIA GPU](#isolating-the-nvidia-gpu)
7. [VM Configuration](#vm-configuration)
8. [First Boot and Driver Installation](#first-boot-and-driver-installation)
9. [Looking Glass Setup](#looking-glass-setup-optional)
10. [Performance Tuning](#performance-tuning)
11. [Troubleshooting](#troubleshooting)
12. [Laptop-Specific Considerations](#laptop-specific-considerations)

---

## Understanding GPU Passthrough

### What Happens

```
BEFORE (Normal):
┌─────────────────────────────────────────────┐
│ Linux Host                                   │
│  ├── Intel HD 630 (Display)                  │
│  └── NVIDIA GTX 1050 Ti (PRIME/Optimus)      │
└─────────────────────────────────────────────┘

AFTER (GPU Passthrough):
┌─────────────────────────────────────────────┐
│ Linux Host                                   │
│  └── Intel HD 630 (Display)                  │
├─────────────────────────────────────────────┤
│ Windows VM (via VFIO)                        │
│  └── NVIDIA GTX 1050 Ti (4GB VRAM)           │
│       └── Full DirectX 12 / OpenGL / Vulkan  │
└─────────────────────────────────────────────┘
```

### Key Concepts

| Term | Meaning |
|------|---------|
| **IOMMU** | Hardware feature that isolates devices into groups for safe passthrough |
| **VFIO** | Linux kernel driver that manages device passthrough to VMs |
| **IOMMU Group** | Set of devices that must be passed through together |
| **vfio-pci** | Driver that claims a device before the normal driver can |
| **Looking Glass** | Software that mirrors VM display to host (no second monitor needed) |

---

## Hardware Requirements Check

### Your Hardware

| Component | Status | Notes |
|-----------|--------|-------|
| CPU (i7-7700HQ) | ✅ VT-x + VT-d | Supports IOMMU |
| Chipset (HM175) | ✅ | Supports VT-d |
| NVIDIA GTX 1050 Ti | ✅ | 4GB VRAM, PCIe |
| Intel HD 630 | ✅ | Will drive host display |

### Requirements Checklist

Run this to verify:

```bash
# Check VT-d support in CPU
grep -E "vmx|svm" /proc/cpuinfo && echo "✓ Virtualization supported"

# Check IOMMU support (after enabling in BIOS)
dmesg | grep -i -e DMAR -e IOMMU

# Check if NVIDIA GPU is in separate IOMMU group (crucial!)
./check-iommu.sh
```

---

## BIOS Configuration

**CRITICAL:** You must enable these settings in BIOS/UEFI.

### Access BIOS

1. Restart laptop
2. Press **F2** repeatedly during boot (Acer uses F2)
3. Enter BIOS Setup

### Settings to Enable

Navigate through the BIOS menus and enable:

| Setting | Location (typical) | Required |
|---------|-------------------|----------|
| **VT-d** / **Intel Virtualization Technology for Directed I/O** | Advanced → CPU Configuration | YES |
| **VT-x** / **Intel Virtualization Technology** | Advanced → CPU Configuration | YES |
| **IOMMU** | Advanced → Chipset (if present) | YES |
| **Above 4G Decoding** | Advanced → PCI Configuration (if present) | Recommended |
| **Secure Boot** | Security → Secure Boot | Disable (or configure) |

### Acer-Specific Notes

On Acer Nitro laptops:
- VT-d may be under "Main" or "Advanced"
- If you don't see VT-d, check for a "DPTF" or "Thermal" setting that may be hiding it
- Some Acer BIOS hide advanced options; you may need to press Ctrl+S or Ctrl+A to reveal them

**Save and reboot** after making changes.

---

## Kernel Configuration

### Step 1: Enable IOMMU in Kernel Parameters

```bash
# Add IOMMU parameters to kernel command line
sudo grubby --update-kernel=ALL --args="intel_iommu=on iommu=pt"

# Verify the change
sudo grubby --info=ALL | grep args
```

**Parameters Explained:**
- `intel_iommu=on` - Enables Intel IOMMU (VT-d)
- `iommu=pt` - Passthrough mode for better performance

### Step 2: Reboot

```bash
sudo reboot
```

### Step 3: Verify IOMMU is Active

```bash
# Check kernel messages for IOMMU
dmesg | grep -i -e DMAR -e IOMMU | head -20

# You should see something like:
# DMAR: IOMMU enabled
# DMAR-IR: Enabled IRQ remapping

# Check IOMMU groups exist
ls /sys/kernel/iommu_groups/
```

---

## IOMMU Group Analysis

This is the **most critical step**. Your NVIDIA GPU must be in its own IOMMU group (or only with its HDMI audio controller).

### Run the Analysis Script

```bash
./check-iommu-detailed.sh
```

Or manually:

```bash
#!/bin/bash
# List all IOMMU groups with devices
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done
done
```

### Ideal Output (What You Want)

```
IOMMU Group 1:
    00:02.0 VGA compatible controller [0300]: Intel Corporation HD Graphics 630 [8086:591b]

IOMMU Group 12:
    01:00.0 3D controller [0302]: NVIDIA Corporation GP107M [GeForce GTX 1050 Ti Mobile] [10de:1c8c]
    01:00.1 Audio device [0403]: NVIDIA Corporation GP107GL High Definition Audio Controller [10de:0fb9]
```

This is ideal because:
- Intel GPU is in its own group (stays with host)
- NVIDIA GPU + its audio are together in a separate group (both pass to VM)

### Problematic Output (Common on Laptops)

```
IOMMU Group 1:
    00:00.0 Host bridge
    00:02.0 Intel HD Graphics 630
    00:14.0 USB controller
    00:1f.0 ISA bridge
    01:00.0 NVIDIA GTX 1050 Ti    <-- Problem!
    01:00.1 NVIDIA Audio
    ... more devices ...
```

If the NVIDIA GPU is grouped with other devices (especially the Intel GPU or root ports), you have two options:

#### Option A: ACS Override Patch (Last Resort)

This kernel patch forces devices into separate groups. It's a security tradeoff.

```bash
# Check if your kernel has ACS override
grep -r "pcie_acs_override" /boot/config-$(uname -r)

# If not, you'll need a custom kernel or the patch
# Fedora doesn't include this by default
```

#### Option B: Use a Different PCIe Slot (Desktop Only)

Not applicable to laptops.

#### Option C: Accept Limitations

Pass through the entire group (all devices in it). This may cause issues if critical devices are included.

---

## Isolating the NVIDIA GPU

We need to prevent Linux from loading the NVIDIA driver so VFIO can claim the GPU at boot.

### Step 1: Find GPU Device IDs

```bash
lspci -nn | grep NVIDIA
```

Output example:
```
01:00.0 3D controller [0302]: NVIDIA Corporation GP107M [GeForce GTX 1050 Ti Mobile] [10de:1c8c] (rev a1)
01:00.1 Audio device [0403]: NVIDIA Corporation GP107GL High Definition Audio Controller [10de:0fb9] (rev a1)
```

**Your IDs:** `10de:1c8c` (GPU) and `10de:0fb9` (Audio)

### Step 2: Configure VFIO to Claim the GPU

Create the VFIO configuration:

```bash
# Create vfio config
sudo tee /etc/modprobe.d/vfio.conf << 'EOF'
options vfio-pci ids=10de:1c8c,10de:0fb9
softdep nvidia pre: vfio-pci
softdep nvidia* pre: vfio-pci
softdep nouveau pre: vfio-pci
EOF
```

### Step 3: Load VFIO Modules Early

```bash
# Add vfio modules to initramfs
sudo tee /etc/dracut.conf.d/vfio.conf << 'EOF'
add_drivers+=" vfio vfio_iommu_type1 vfio_pci "
EOF

# Rebuild initramfs
sudo dracut -f --kver $(uname -r)
```

### Step 4: Blacklist NVIDIA Drivers (Belt and Suspenders)

```bash
sudo tee /etc/modprobe.d/blacklist-nvidia.conf << 'EOF'
# Blacklist NVIDIA drivers - GPU is for VM passthrough
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
EOF
```

### Step 5: Reboot and Verify

```bash
sudo reboot

# After reboot, check VFIO claimed the GPU
lspci -nnk | grep -A 3 NVIDIA
```

Expected output:
```
01:00.0 3D controller [0302]: NVIDIA Corporation GP107M [10de:1c8c] (rev a1)
    Subsystem: Acer Incorporated [ALI] [1025:1182]
    Kernel driver in use: vfio-pci    <-- SUCCESS!
01:00.1 Audio device [0403]: NVIDIA Corporation GP107GL [10de:0fb9] (rev a1)
    Kernel driver in use: vfio-pci    <-- SUCCESS!
```

If it says `nvidia` or `nouveau` instead of `vfio-pci`, the binding didn't work.

---

## VM Configuration

### Create VM with GPU Passthrough

I'll provide a complete script, but here's the key XML for the GPU:

```xml
<!-- GPU PCI Device -->
<hostdev mode="subsystem" type="pci" managed="yes">
  <source>
    <address domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
  </source>
  <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
</hostdev>

<!-- GPU Audio (HDMI) -->
<hostdev mode="subsystem" type="pci" managed="yes">
  <source>
    <address domain="0x0000" bus="0x01" slot="0x00" function="0x1"/>
  </source>
  <address type="pci" domain="0x0000" bus="0x07" slot="0x00" function="0x0"/>
</hostdev>
```

### Use the Passthrough Script

```bash
./04-create-vm-gpu-passthrough.sh
```

### Critical VM Settings

| Setting | Value | Reason |
|---------|-------|--------|
| Machine Type | `q35` | Modern chipset with proper PCIe |
| CPU Mode | `host-passthrough` | Exposes real CPU features |
| Hide Hypervisor | `on` | NVIDIA drivers check for VMs |
| UEFI Boot | Required | Modern GPU needs UEFI |
| TPM 2.0 | Yes | Windows 11 requirement |

### NVIDIA Driver Anti-VM Detection

NVIDIA drivers refuse to work if they detect a hypervisor. Add these to VM XML:

```xml
<features>
  <hyperv mode="custom">
    <relaxed state="on"/>
    <vapic state="on"/>
    <spinlocks state="on" retries="8191"/>
    <vendor_id state="on" value="randomid"/>
  </hyperv>
  <kvm>
    <hidden state="on"/>
  </kvm>
</features>

<cpu mode="host-passthrough" check="none" migratable="on">
  <topology sockets="1" dies="1" cores="4" threads="1"/>
  <feature policy="disable" name="hypervisor"/>
</cpu>
```

---

## First Boot and Driver Installation

### Boot Process

1. Start VM: `virsh start windows11-sketchup-gpu`
2. Connect via SPICE initially (GPU won't show output until drivers installed)
3. You should see the QXL display

### Install NVIDIA Drivers in Windows

1. Download NVIDIA drivers from nvidia.com (NOT GeForce Experience)
   - Get the **Game Ready Driver** or **Studio Driver**
   - Version 550+ recommended

2. Run installer
3. Reboot when prompted

### After Driver Installation

The NVIDIA GPU should now be visible in Device Manager:
- Display adapters → NVIDIA GeForce GTX 1050 Ti

### Switching to GPU Output

**Option A: Physical Second Monitor**
- Connect monitor to laptop HDMI/miniDP port
- GPU output appears on that monitor

**Option B: Looking Glass (Recommended for Laptops)**
- See next section

**Option C: HDMI Dummy Plug**
- Plug a dummy HDMI adapter to fool the GPU into outputting
- Use Looking Glass to view

---

## Looking Glass Setup (Recommended)

Looking Glass creates a shared memory buffer between host and guest, allowing you to view the GPU output on your Linux host without a second monitor.

### Why Looking Glass?

On a laptop like yours:
- The NVIDIA GPU may output through the Intel GPU (Optimus)
- Or it may have no external ports connected directly
- Looking Glass solves this by sharing the framebuffer

### Install on Fedora Host

```bash
# Install Looking Glass client
sudo dnf install looking-glass-client

# Or build from source for latest version
# https://looking-glass.io/downloads
```

### Configure Shared Memory

```bash
# Create shared memory config
sudo tee /etc/tmpfiles.d/10-looking-glass.conf << EOF
f /dev/shm/looking-glass 0660 $(whoami) kvm -
EOF

# Create it now
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf
```

### Add to VM XML

```xml
<shmem name="looking-glass">
  <model type="ivshmem-plain"/>
  <size unit="M">64</size>
</shmem>
```

The size should be calculated as:
```
width x height x 4 x 2 = bytes
1920 x 1080 x 4 x 2 = ~16MB (use 32 or 64 for safety)
```

### Install in Windows Guest

1. Download Looking Glass Host from https://looking-glass.io/downloads
2. Run `looking-glass-host-setup.exe`
3. Reboot

### Run Looking Glass

```bash
# On Linux host
looking-glass-client -F  # -F for fullscreen
```

You now see the Windows VM with full GPU acceleration in a window on your Linux desktop!

---

## Performance Tuning

### CPU Pinning

Pin vCPUs to physical cores to prevent context switching:

```xml
<vcpu placement="static">4</vcpu>
<cputune>
  <vcpupin vcpu="0" cpuset="4"/>
  <vcpupin vcpu="1" cpuset="5"/>
  <vcpupin vcpu="2" cpuset="6"/>
  <vcpupin vcpu="3" cpuset="7"/>
  <emulatorpin cpuset="0-3"/>
</cputune>
```

Your i7-7700HQ has 4 cores / 8 threads:
- Cores 0-3: Physical cores 0-3
- Cores 4-7: Hyperthreads

Pin VM to cores 4-7 (hyperthreads), leave 0-3 for host.

### Huge Pages

```bash
# For 8GB VM: 8388608KB / 2048 = 4096 pages
echo 4096 | sudo tee /proc/sys/vm/nr_hugepages

# Make permanent
echo "vm.nr_hugepages = 4096" | sudo tee /etc/sysctl.d/hugepages.conf

# Add to VM XML
<memoryBacking>
  <hugepages/>
</memoryBacking>
```

### Disk I/O

Already covered - use virtio-blk with writeback caching.

### Network

Use virtio-net for best performance.

---

## Troubleshooting

### GPU Not Claimed by vfio-pci

```bash
# Check what driver is bound
lspci -nnk | grep -A 3 NVIDIA

# If nvidia is bound, check modprobe order
cat /etc/modprobe.d/vfio.conf

# Verify initramfs has vfio
lsinitrd | grep vfio
```

### VM Fails to Start - IOMMU Error

```
error: internal error: qemu unexpectedly closed the monitor:
vfio: failed to set iommu for container: Operation not permitted
```

**Causes:**
- IOMMU not enabled in BIOS
- Kernel parameter missing
- Device still bound to nvidia driver

### Black Screen After GPU Passthrough

**Causes:**
- GPU needs UEFI GOP (Graphics Output Protocol)
- Some laptop GPUs don't have video BIOS for external output

**Solutions:**
1. Use Looking Glass instead of physical output
2. Try adding a GPU ROM file (dump from Windows)

### NVIDIA Error 43

The dreaded "Code 43" in Device Manager.

**Cause:** NVIDIA detected it's running in a VM.

**Fix:** Add hypervisor hiding to VM XML (covered above):
```xml
<kvm>
  <hidden state="on"/>
</kvm>
<features>
  <hyperv>
    <vendor_id state="on" value="123456789ab"/>
  </hyperv>
</features>
```

### Audio Crackling/Stuttering

```xml
<qemu:commandline>
  <qemu:arg value="-audiodev"/>
  <qemu:arg value="id=audio1,driver=spice,timer-period=5000"/>
</qemu:commandline>
```

---

## Laptop-Specific Considerations

### Your Acer Nitro AN515-51

This laptop uses **NVIDIA Optimus** - the NVIDIA GPU is connected *through* the Intel GPU for display output. This creates complications:

| Scenario | Status |
|----------|--------|
| NVIDIA has direct HDMI output | Check your ports - if HDMI goes to NVIDIA, you can use external monitor |
| NVIDIA outputs via Intel (MUX-less) | Need Looking Glass or dummy plug |
| External monitor on Intel | Can't get NVIDIA output without Looking Glass |

### Check Your Ports

```bash
# Show port connections
cat /sys/class/drm/card*/*/status
```

Or in Linux:
- Settings → Display
- Connect external monitor, see which GPU is listed

### MUX Switch (If Available)

Some gaming laptops have a MUX switch (in BIOS) to connect the display directly to the NVIDIA GPU. Check your BIOS for:
- "Display Mode"
- "GPU Mode"
- "Discrete Graphics Mode"
- "Optimus" toggle

If you can switch to discrete-only mode, GPU passthrough becomes much simpler.

---

## Complete Setup Script

See `04-create-vm-gpu-passthrough.sh` for a complete script that:

1. Verifies VFIO is binding correctly
2. Creates an optimized VM with GPU passthrough
3. Configures hypervisor hiding
4. Sets up Looking Glass shared memory
5. Enables CPU pinning and huge pages

---

## Summary Checklist

- [ ] Enable VT-d and IOMMU in BIOS
- [ ] Add `intel_iommu=on iommu=pt` to kernel parameters
- [ ] Reboot and verify IOMMU groups with `./check-iommu.sh`
- [ ] Verify NVIDIA GPU is in its own group (or only with its audio)
- [ ] Configure vfio-pci to claim NVIDIA GPU at boot
- [ ] Blacklist nvidia/nouveau drivers
- [ ] Rebuild initramfs with `dracut -f`
- [ ] Reboot and verify `lspci -nnk` shows `vfio-pci` driver
- [ ] Create VM with GPU passthrough XML
- [ ] Add hypervisor hiding to prevent Error 43
- [ ] Install NVIDIA drivers in Windows
- [ ] Set up Looking Glass for display output
- [ ] Configure CPU pinning and huge pages for performance

---

## Resources

- [Arch Wiki - PCI Passthrough](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [Looking Glass Documentation](https://looking-glass.io/docs)
- [Level1Techs GPU Passthrough Guide](https://forum.level1techs.com/t/play-games-in-windows-on-linux-pci-passthrough-quick-guide/108981)
- [VFIO Reddit Community](https://www.reddit.com/r/VFIO/)
- [NVIDIA GPU Passthrough Troubleshooting](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#NVIDIA_GPU)

---

*Document created: 2026-01-23*
*For: Acer Nitro AN515-51 with i7-7700HQ + GTX 1050 Ti*
*Part of HOLYFUCKINGWINE SketchUp 2026 on Linux project*
