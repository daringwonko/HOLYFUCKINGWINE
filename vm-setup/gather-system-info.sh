#!/bin/bash
##############################################################################
# System Information Gathering Script
# Collects hardware/software info for VM setup troubleshooting
##############################################################################

OUTPUT_FILE="system-info-$(date +%Y%m%d-%H%M%S).txt"

{
echo "========================================"
echo "System Information Report"
echo "Generated: $(date)"
echo "========================================"
echo ""

echo "=== OS Information ==="
cat /etc/os-release 2>/dev/null | grep -E "^(NAME|VERSION|ID)="
uname -a
echo ""

echo "=== CPU Information ==="
lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket|Virtualization|CPU family|Model:|Stepping"
echo ""

echo "=== Virtualization Support ==="
echo "VT-x/AMD-V in /proc/cpuinfo:"
grep -c -E "vmx|svm" /proc/cpuinfo 2>/dev/null || echo "Not found"
echo ""
echo "KVM modules loaded:"
lsmod | grep kvm || echo "KVM not loaded"
echo ""

echo "=== Memory ==="
free -h
echo ""

echo "=== Storage Devices ==="
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL 2>/dev/null || lsblk
echo ""

echo "=== GPU Information ==="
lspci | grep -E "VGA|3D|Display"
echo ""
echo "NVIDIA Driver:"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "nvidia-smi not available"
echo ""

echo "=== IOMMU Status ==="
if [ -d /sys/kernel/iommu_groups ]; then
    echo "IOMMU Groups found: $(ls /sys/kernel/iommu_groups | wc -l)"
    echo ""
    echo "GPU IOMMU Groups:"
    for g in /sys/kernel/iommu_groups/*/devices/*; do
        DEVICE=${g##*/}
        DESC=$(lspci -nns "$DEVICE" 2>/dev/null)
        if echo "$DESC" | grep -qi "VGA\|3D\|Display"; then
            echo "  Group $(basename $(dirname $(dirname $g))): $DESC"
        fi
    done
else
    echo "IOMMU not enabled"
fi
echo ""

echo "=== Libvirt Status ==="
systemctl is-active libvirtd 2>/dev/null || echo "libvirtd not installed"
virsh version 2>/dev/null || echo "virsh not available"
echo ""

echo "=== User Groups ==="
groups
echo ""

echo "=== Kernel Parameters ==="
cat /proc/cmdline
echo ""

echo "=== BIOS/UEFI Mode ==="
if [ -d /sys/firmware/efi ]; then
    echo "System booted in UEFI mode"
else
    echo "System booted in Legacy BIOS mode"
fi
echo ""

echo "=== Disk Space ==="
df -h / /home 2>/dev/null
echo ""

echo "=== Network (default libvirt) ==="
virsh net-list --all 2>/dev/null || echo "libvirt not available"
echo ""

} | tee "$OUTPUT_FILE"

echo ""
echo "========================================"
echo "Report saved to: $OUTPUT_FILE"
echo "========================================"
