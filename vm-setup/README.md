# Windows VM Setup for SketchUp Extraction

This directory contains everything needed to create a Windows 11 VM on Fedora 42 using KVM/QEMU, install SketchUp 2026, and extract the files for use in Wine/Bottles.

## Quick Start (Standard VM - No GPU Passthrough)

```bash
# 1. Install KVM/QEMU (requires sudo, then logout/login)
./01-install-kvm.sh

# 2. Download VirtIO drivers + get Windows 11 ISO
./02-download-resources.sh

# 3. Create and launch Windows VM
./03-create-windows-vm.sh

# 4. In Windows: Install SketchUp, run extract-sketchup.ps1
# 5. Back on Linux: ./copy-from-windows.sh ~/vm-shared/sketchup-extraction
```

## Quick Start (GPU Passthrough - Run SketchUp in VM)

```bash
# 1-2. Same as above

# 3. Check IOMMU groups (NVIDIA must be isolated)
./check-iommu-detailed.sh

# 4. Configure vfio-pci binding (see GPU-PASSTHROUGH-GUIDE.md)

# 5. Create VM with GPU passthrough
./04-create-vm-gpu-passthrough.sh

# 6. Install Windows, NVIDIA drivers, Looking Glass
# 7. Run SketchUp with full GPU acceleration!
```

## Files

| Script | Purpose |
|--------|---------|
| `01-install-kvm.sh` | Installs KVM/QEMU, libvirt, virt-manager |
| `02-download-resources.sh` | Downloads VirtIO drivers, guides Windows ISO download |
| `03-create-windows-vm.sh` | Creates optimized Windows 11 VM (software GPU) |
| `04-create-vm-gpu-passthrough.sh` | Creates VM with NVIDIA GPU passthrough |
| `check-iommu.sh` | Quick IOMMU group check |
| `check-iommu-detailed.sh` | Comprehensive GPU passthrough readiness check |
| `gather-system-info.sh` | Collects system info for troubleshooting |
| `extract-sketchup.ps1` | PowerShell script to run in Windows VM |
| `KVM-WINDOWS-VM-GUIDE.md` | Comprehensive VM setup guide |
| `GPU-PASSTHROUGH-GUIDE.md` | Complete GPU passthrough (VFIO) guide |

## System Requirements

Tested on:
- **CPU:** Intel Core i7-7700HQ (VT-x enabled)
- **RAM:** 16GB (8GB allocated to VM)
- **GPU:** Intel HD 630 + NVIDIA GTX 1050 Ti
- **OS:** Fedora 42 Workstation

## Why This Approach?

The SketchUp 2026 installer uses InstallShield 2024 which requires Windows Update Agent COM interfaces that Wine doesn't implement. The installer cannot run in Wine, but the installed application works fine. This VM setup lets you:

1. Install SketchUp in a real Windows environment
2. Extract the installed files
3. Import them into Wine/Bottles on Linux

See `WINDOWS-VM-EXTRACTION-GUIDE.md` in the parent directory for the complete workflow.
