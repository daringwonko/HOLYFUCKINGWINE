# KVM/QEMU Windows 11 VM Setup Guide for Fedora 42

## Overview

This guide sets up a high-performance Windows 11 VM on Fedora 42 using KVM/QEMU with virtio drivers. The VM will be used to install SketchUp 2026 and extract the files to your Linux system.

**Expected Performance:** Near-native, potentially *faster* than bare-metal Windows for I/O operations due to Linux's superior storage stack.

---

## Quick Start (TL;DR)

```bash
cd vm-setup

# 1. Install KVM and all dependencies
./01-install-kvm.sh

# 2. Logout and login (to apply group membership)

# 3. Download Windows 11 ISO and virtio drivers
./02-download-resources.sh

# 4. Create the Windows VM
./03-create-windows-vm.sh

# 5. Follow the Windows installation, then run inside Windows:
#    - Install virtio drivers from the mounted CD
#    - Install SketchUp 2026
#    - Run the extraction PowerShell script
```

---

## Prerequisites

### Hardware Requirements
- **CPU:** Intel VT-x or AMD-V capable (you have VT-x)
- **RAM:** 8GB minimum, 16GB+ recommended (you have 21GB)
- **Storage:** 60GB+ free space for VM disk image
- **GPU:** Any (GPU passthrough optional)

### Software Requirements
- Fedora 42 Workstation
- Internet connection (for initial setup)
- Windows 11 ISO (download instructions included)

---

## Phase 1: Install KVM/QEMU Stack

### What Gets Installed

| Package | Purpose |
|---------|---------|
| `@virtualization` | Meta-package: QEMU, libvirt, virt-manager |
| `virt-manager` | GUI for managing VMs |
| `libvirt-daemon-kvm` | KVM hypervisor daemon |
| `qemu-kvm` | QEMU with KVM acceleration |
| `edk2-ovmf` | UEFI firmware for VMs |
| `swtpm` | Software TPM (required for Windows 11) |

### Run the Install Script

```bash
./01-install-kvm.sh
```

Or manually:

```bash
# Install virtualization stack
sudo dnf install -y @virtualization virt-manager libvirt-daemon-kvm \
    qemu-kvm edk2-ovmf swtpm swtpm-tools

# Add yourself to required groups
sudo usermod -aG libvirt,kvm $(whoami)

# Enable and start libvirtd
sudo systemctl enable --now libvirtd

# Verify KVM is working
virt-host-validate
```

**IMPORTANT:** Log out and log back in after adding yourself to the groups!

---

## Phase 2: Download Required Resources

### Windows 11 ISO

Microsoft provides free Windows 11 ISOs for evaluation:

1. Go to: https://www.microsoft.com/software-download/windows11
2. Select "Windows 11 (multi-edition ISO for x64 devices)"
3. Choose your language
4. Download the ISO (~6GB)

Or use the script which provides instructions:
```bash
./02-download-resources.sh
```

### VirtIO Drivers (Critical for Performance)

The VirtIO drivers are what make the VM fast. Without them, you get emulated hardware which is 10x slower.

```bash
# Download latest stable virtio-win ISO
wget -O ~/virtio-win.iso \
    https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

---

## Phase 3: Create the Windows 11 VM

### Option A: Use the Script (Recommended)

```bash
./03-create-windows-vm.sh
```

This creates an optimized VM with:
- 8GB RAM (adjustable)
- 4 vCPUs (adjustable)
- 80GB virtio disk (thin provisioned)
- UEFI boot with Secure Boot
- TPM 2.0 emulation
- VirtIO network adapter
- Shared folder via virtiofs

### Option B: Use virt-manager GUI

1. Open **Virtual Machine Manager**
2. Click **Create a new virtual machine**
3. Select **Local install media (ISO)**
4. Browse to your Windows 11 ISO
5. Set RAM to 8192 MB, CPUs to 4
6. Create a 80GB disk (select **Customize before install**)
7. In customization:
   - **Overview:** Change firmware to `UEFI x86_64: /usr/share/edk2/ovmf/OVMF_CODE.secboot.fd`
   - **Add Hardware → TPM:** Type: Emulated, Model: TMP 2.0
   - **Disk:** Change bus to **VirtIO**
   - **NIC:** Change to **virtio**
   - **Add Hardware → Storage:** Add virtio-win.iso as CDROM

### Option C: Import Pre-configured XML

```bash
# Use the provided optimized XML template
virsh define windows11-sketchup.xml

# Start the VM
virsh start windows11-sketchup
virt-viewer windows11-sketchup
```

---

## Phase 4: Install Windows 11

### During Installation

1. Boot the VM
2. Windows setup will start
3. When asked "Where do you want to install Windows?", you'll see **no drives**
4. Click **Load driver**
5. Browse to the virtio-win CD: `E:\amd64\w11\` (or similar)
6. Select **Red Hat VirtIO SCSI controller**
7. Now your disk appears - proceed with installation

### After Installation

1. Open File Explorer
2. Go to the virtio-win CD drive
3. Run `virtio-win-gt-x64.msi` to install all drivers
4. Reboot when prompted

### Verify VirtIO is Working

In Device Manager, you should see:
- Red Hat VirtIO SCSI Controller
- Red Hat VirtIO Ethernet Adapter
- Red Hat VirtIO Balloon Driver

---

## Phase 5: Set Up Shared Folder

### Method 1: VirtioFS (Fastest, Recommended)

Already configured if you used the script. In Windows, the share appears as a network drive.

```bash
# On Linux host, add to VM XML or use:
virsh edit windows11-sketchup

# Add inside <devices>:
<filesystem type="mount" accessmode="passthrough">
  <driver type="virtiofs"/>
  <source dir="/home/yourusername/vm-shared"/>
  <target dir="shared"/>
</filesystem>
```

In Windows, mount in PowerShell:
```powershell
net use Z: \\?\virtiofs\shared
```

### Method 2: SPICE Shared Folder

1. In virt-manager, add a **Channel** device with spice
2. Install SPICE Guest Tools in Windows
3. Right-click SPICE icon in system tray → Configure shared folder

### Method 3: SMB/Samba (Most Compatible)

```bash
# On Fedora host
sudo dnf install samba
mkdir -p ~/vm-shared
sudo smbpasswd -a $(whoami)

# Add to /etc/samba/smb.conf:
[vm-shared]
    path = /home/yourusername/vm-shared
    browseable = yes
    read only = no
    valid users = yourusername

sudo systemctl enable --now smb
```

In Windows, map network drive to `\\192.168.122.1\vm-shared`

---

## Phase 6: Install SketchUp 2026

1. Copy SketchUp installer to shared folder (on Linux)
2. In Windows VM, access the shared folder
3. Run the SketchUp installer
4. Complete installation normally

---

## Phase 7: Extract SketchUp Files

Run this PowerShell script in Windows (included in `extract-sketchup.ps1`):

```powershell
# Create extraction directory on shared folder
$staging = "Z:\sketchup-extraction"
New-Item -ItemType Directory -Force -Path $staging

# Copy Program Files
Copy-Item -Recurse -Force "C:\Program Files\SketchUp\SketchUp 2026" "$staging\Program Files\SketchUp\"

# Copy AppData
$user = $env:USERNAME
Copy-Item -Recurse -Force "C:\Users\$user\AppData\Roaming\SketchUp" "$staging\AppData\Roaming\" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "C:\Users\$user\AppData\Local\SketchUp" "$staging\AppData\Local\" -ErrorAction SilentlyContinue

# Copy ProgramData
Copy-Item -Recurse -Force "C:\ProgramData\SketchUp" "$staging\ProgramData\" -ErrorAction SilentlyContinue

# Export registry
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\SketchUp" "$staging\sketchup-hklm.reg" /y
reg export "HKEY_CURRENT_USER\SOFTWARE\SketchUp" "$staging\sketchup-hkcu.reg" /y

Write-Host "Extraction complete! Files are in: $staging"
```

---

## Phase 8: Import to Bottles

Back on Fedora, run:

```bash
cd /path/to/HOLYFUCKINGWINE
./copy-from-windows.sh ~/vm-shared/sketchup-extraction
```

---

## Performance Tuning

### Enable Huge Pages (Recommended for 8GB+ VM)

```bash
# Calculate pages needed: RAM in KB / 2048
# For 8GB: 8388608 / 2048 = 4096 pages
echo 4096 | sudo tee /proc/sys/vm/nr_hugepages

# Make permanent
echo "vm.nr_hugepages = 4096" | sudo tee /etc/sysctl.d/hugepages.conf
```

### CPU Pinning (Optional)

Edit VM XML to pin vCPUs to physical cores:

```xml
<vcpu placement="static">4</vcpu>
<cputune>
  <vcpupin vcpu="0" cpuset="0"/>
  <vcpupin vcpu="1" cpuset="1"/>
  <vcpupin vcpu="2" cpuset="2"/>
  <vcpupin vcpu="3" cpuset="3"/>
</cputune>
```

### Use io_uring (Fedora 42+)

Newer QEMU supports io_uring for even faster I/O:

```xml
<driver name="qemu" type="qcow2" io="io_uring"/>
```

---

## GPU Passthrough (Optional - For Running SketchUp in VM)

If you want to actually run SketchUp inside the VM with GPU acceleration:

### Requirements
- Two GPUs (Intel iGPU + NVIDIA dGPU)
- IOMMU enabled in BIOS
- NVIDIA GPU in separate IOMMU group

### Quick Check

```bash
# Check IOMMU groups
./check-iommu.sh
```

If your NVIDIA GPU is in its own group, passthrough is possible. This is an advanced topic - see the Arch Wiki article on PCI Passthrough for details.

---

## Troubleshooting

### "KVM not available"

```bash
# Check CPU supports virtualization
grep -E "vmx|svm" /proc/cpuinfo

# Ensure KVM module is loaded
sudo modprobe kvm_intel  # or kvm_amd

# Check for errors
dmesg | grep -i kvm
```

### Windows 11 "This PC can't run Windows 11"

TPM not configured. Ensure you added TPM 2.0 device to VM.

### Disk Not Visible During Install

VirtIO driver not loaded. Load from virtio-win ISO during install.

### Network Not Working

Ensure virtio NIC is configured and driver installed in Windows.

### Shared Folder Not Mounting

For virtiofs, ensure `virtiofsd` is running:
```bash
sudo systemctl status virtiofsd
```

---

## Files Included

| File | Purpose |
|------|---------|
| `01-install-kvm.sh` | Installs KVM/QEMU stack |
| `02-download-resources.sh` | Downloads virtio drivers |
| `03-create-windows-vm.sh` | Creates optimized Windows VM |
| `windows11-sketchup.xml` | Pre-configured libvirt XML |
| `extract-sketchup.ps1` | PowerShell extraction script |
| `check-iommu.sh` | Checks IOMMU groups for GPU passthrough |
| `gather-system-info.sh` | Collects system info for troubleshooting |

---

## Quick Reference

```bash
# Start VM
virsh start windows11-sketchup

# Connect to VM console
virt-viewer windows11-sketchup

# Shutdown VM gracefully
virsh shutdown windows11-sketchup

# Force stop (if hung)
virsh destroy windows11-sketchup

# List all VMs
virsh list --all

# Delete VM (keeps disk)
virsh undefine windows11-sketchup

# Delete VM and disk
virsh undefine windows11-sketchup --remove-all-storage
```

---

*Document created: 2026-01-23*
*Part of HOLYFUCKINGWINE SketchUp 2026 on Linux project*
