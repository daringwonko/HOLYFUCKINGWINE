#!/bin/bash
##############################################################################
# Create Windows 11 VM with NVIDIA GPU Passthrough
# For: Acer Nitro AN515-51 (i7-7700HQ + GTX 1050 Ti)
#
# Prerequisites:
#   - IOMMU enabled (intel_iommu=on)
#   - NVIDIA GPU bound to vfio-pci driver
#   - VirtIO and Windows ISOs downloaded
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}! $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

# Configuration
VM_NAME="windows11-sketchup-gpu"
VM_RAM_MB=8192          # 8GB
VM_CPUS=4               # 4 vCPUs (leave 4 for host)
VM_DISK_GB=100          # 100GB for SketchUp + Windows
VM_IMAGES_DIR="$HOME/VMs"
VM_SHARED_DIR="$HOME/vm-shared"
ISO_DIR="$HOME/ISOs"
LOOKING_GLASS_SIZE=64   # MB for shared memory

print_header "Windows 11 VM with GPU Passthrough"

echo "This script creates an optimized Windows 11 VM with your"
echo "NVIDIA GTX 1050 Ti passed through for full GPU acceleration."
echo ""
echo "Configuration:"
echo "  VM Name:     $VM_NAME"
echo "  RAM:         ${VM_RAM_MB}MB (8GB)"
echo "  CPUs:        $VM_CPUS vCPUs (pinned)"
echo "  Disk:        ${VM_DISK_GB}GB"
echo "  GPU:         NVIDIA GTX 1050 Ti (passthrough)"
echo "  Display:     Looking Glass + SPICE fallback"
echo ""

# ============================================================================
# Preflight Checks
# ============================================================================
print_header "Preflight Checks"

# Check libvirtd
if ! systemctl is-active --quiet libvirtd; then
    print_error "libvirtd is not running"
    exit 1
fi
print_success "libvirtd is running"

# Check user groups
if ! groups | grep -q libvirt; then
    print_error "User not in libvirt group"
    exit 1
fi
print_success "User in libvirt group"

# Find NVIDIA GPU
NVIDIA_BDF=$(lspci -nn | grep -i "NVIDIA" | grep -v "Audio" | head -1 | awk '{print $1}')
if [ -z "$NVIDIA_BDF" ]; then
    print_error "NVIDIA GPU not found"
    exit 1
fi

# Check if bound to vfio-pci
NVIDIA_DRIVER=$(lspci -nnk -s "$NVIDIA_BDF" | grep "Kernel driver" | awk '{print $NF}')
if [ "$NVIDIA_DRIVER" != "vfio-pci" ]; then
    print_error "NVIDIA GPU not bound to vfio-pci (current: $NVIDIA_DRIVER)"
    echo ""
    echo "Please follow GPU-PASSTHROUGH-GUIDE.md to configure vfio-pci binding"
    exit 1
fi
print_success "NVIDIA GPU ($NVIDIA_BDF) bound to vfio-pci"

# Find NVIDIA Audio
NVIDIA_AUDIO_BDF=$(lspci -nn | grep -i "NVIDIA" | grep "Audio" | head -1 | awk '{print $1}')
if [ -n "$NVIDIA_AUDIO_BDF" ]; then
    print_success "NVIDIA Audio ($NVIDIA_AUDIO_BDF) found"
fi

# Convert BDF to domain:bus:slot.function format for libvirt
# Input: 01:00.0 -> Output: 0x0000, 0x01, 0x00, 0x0
parse_bdf() {
    local bdf=$1
    local bus=$(echo $bdf | cut -d: -f1)
    local slot_func=$(echo $bdf | cut -d: -f2)
    local slot=$(echo $slot_func | cut -d. -f1)
    local func=$(echo $slot_func | cut -d. -f2)
    echo "0x$bus 0x$slot 0x$func"
}

read GPU_BUS GPU_SLOT GPU_FUNC <<< $(parse_bdf $NVIDIA_BDF)
print_success "GPU address: bus=$GPU_BUS slot=$GPU_SLOT func=$GPU_FUNC"

if [ -n "$NVIDIA_AUDIO_BDF" ]; then
    read AUDIO_BUS AUDIO_SLOT AUDIO_FUNC <<< $(parse_bdf $NVIDIA_AUDIO_BDF)
fi

# Find ISOs
WIN_ISO=$(ls "$ISO_DIR"/Win11*.iso 2>/dev/null | head -1)
if [ -z "$WIN_ISO" ]; then
    WIN_ISO=$(ls "$HOME/Downloads"/Win11*.iso 2>/dev/null | head -1)
fi
if [ -z "$WIN_ISO" ]; then
    print_error "Windows 11 ISO not found"
    exit 1
fi
print_success "Windows ISO: $WIN_ISO"

VIRTIO_ISO="$ISO_DIR/virtio-win.iso"
if [ ! -f "$VIRTIO_ISO" ]; then
    VIRTIO_ISO=$(ls "$HOME/Downloads"/virtio-win*.iso 2>/dev/null | head -1)
fi
if [ -z "$VIRTIO_ISO" ] || [ ! -f "$VIRTIO_ISO" ]; then
    print_error "VirtIO drivers ISO not found"
    exit 1
fi
print_success "VirtIO ISO: $VIRTIO_ISO"

echo ""

# ============================================================================
# Check for Existing VM
# ============================================================================
if virsh list --all | grep -q "$VM_NAME"; then
    print_warning "VM '$VM_NAME' already exists"
    read -p "Delete and recreate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        virsh destroy "$VM_NAME" 2>/dev/null || true
        virsh undefine "$VM_NAME" --nvram 2>/dev/null || true
        rm -f "$VM_IMAGES_DIR/$VM_NAME.qcow2"
        print_success "Old VM removed"
    else
        echo "Exiting."
        exit 0
    fi
fi

# ============================================================================
# Create Resources
# ============================================================================
print_header "Creating Resources"

mkdir -p "$VM_IMAGES_DIR"
mkdir -p "$VM_SHARED_DIR"

# Create disk
DISK_PATH="$VM_IMAGES_DIR/$VM_NAME.qcow2"
echo "Creating ${VM_DISK_GB}GB disk image..."
qemu-img create -f qcow2 -o preallocation=metadata "$DISK_PATH" "${VM_DISK_GB}G"
print_success "Disk created: $DISK_PATH"

# Create Looking Glass shared memory
echo "Configuring Looking Glass shared memory..."
sudo tee /etc/tmpfiles.d/10-looking-glass.conf > /dev/null << EOF
f /dev/shm/looking-glass 0660 $(whoami) kvm -
EOF
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf 2>/dev/null || true
print_success "Looking Glass shared memory configured"

# Create hugepages (optional, for better performance)
CURRENT_HUGEPAGES=$(cat /proc/sys/vm/nr_hugepages)
NEEDED_HUGEPAGES=$((VM_RAM_MB * 1024 / 2048))
if [ "$CURRENT_HUGEPAGES" -lt "$NEEDED_HUGEPAGES" ]; then
    echo "Allocating huge pages for VM memory..."
    echo $NEEDED_HUGEPAGES | sudo tee /proc/sys/vm/nr_hugepages > /dev/null
    print_success "Allocated $NEEDED_HUGEPAGES huge pages"
fi

echo ""

# ============================================================================
# Generate VM XML
# ============================================================================
print_header "Generating VM Configuration"

# Generate random vendor ID for hypervisor hiding
VENDOR_ID=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 12)

cat > /tmp/${VM_NAME}.xml << XMLEOF
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>${VM_NAME}</name>
  <metadata>
    <description>Windows 11 with NVIDIA GTX 1050 Ti passthrough for SketchUp 2026</description>
  </metadata>
  <memory unit='MiB'>${VM_RAM_MB}</memory>
  <currentMemory unit='MiB'>${VM_RAM_MB}</currentMemory>
  <memoryBacking>
    <hugepages/>
  </memoryBacking>
  <vcpu placement='static'>${VM_CPUS}</vcpu>
  <cputune>
    <!-- Pin to hyperthreads, leave physical cores for host -->
    <vcpupin vcpu='0' cpuset='4'/>
    <vcpupin vcpu='1' cpuset='5'/>
    <vcpupin vcpu='2' cpuset='6'/>
    <vcpupin vcpu='3' cpuset='7'/>
    <emulatorpin cpuset='0-3'/>
  </cputune>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <loader readonly='yes' type='pflash'>/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd</loader>
    <nvram template='/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd'/>
    <boot dev='cdrom'/>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode='custom'>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
      <vpindex state='on'/>
      <runtime state='on'/>
      <synic state='on'/>
      <stimer state='on'/>
      <reset state='on'/>
      <vendor_id state='on' value='${VENDOR_ID}'/>
      <frequencies state='on'/>
    </hyperv>
    <kvm>
      <hidden state='on'/>
    </kvm>
    <vmport state='off'/>
    <smm state='on'/>
    <ioapic driver='kvm'/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='off'>
    <topology sockets='1' dies='1' cores='${VM_CPUS}' threads='1'/>
    <cache mode='passthrough'/>
    <feature policy='require' name='topoext'/>
    <feature policy='disable' name='hypervisor'/>
  </cpu>
  <clock offset='localtime'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
    <timer name='hypervclock' present='yes'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>

    <!-- VirtIO Disk -->
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
      <source file='${DISK_PATH}'/>
      <target dev='vda' bus='virtio'/>
    </disk>

    <!-- Windows 11 ISO -->
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${WIN_ISO}'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
    </disk>

    <!-- VirtIO Drivers ISO -->
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${VIRTIO_ISO}'/>
      <target dev='sdb' bus='sata'/>
      <readonly/>
    </disk>

    <!-- VirtIO Network -->
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>

    <!-- SPICE Display (fallback before GPU driver) -->
    <graphics type='spice' autoport='yes'>
      <listen type='address'/>
      <image compression='auto_glz'/>
      <streaming mode='filter'/>
    </graphics>

    <!-- Video (minimal, GPU does real work) -->
    <video>
      <model type='none'/>
    </video>

    <!-- TPM 2.0 (Required for Windows 11) -->
    <tpm model='tpm-tis'>
      <backend type='emulator' version='2.0'/>
    </tpm>

    <!-- NVIDIA GPU Passthrough -->
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='${GPU_BUS}' slot='${GPU_SLOT}' function='${GPU_FUNC}'/>
      </source>
      <rom bar='on'/>
    </hostdev>

XMLEOF

# Add NVIDIA Audio if present
if [ -n "$NVIDIA_AUDIO_BDF" ]; then
cat >> /tmp/${VM_NAME}.xml << XMLEOF
    <!-- NVIDIA HDMI Audio -->
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='${AUDIO_BUS}' slot='${AUDIO_SLOT}' function='${AUDIO_FUNC}'/>
      </source>
    </hostdev>

XMLEOF
fi

# Continue XML
cat >> /tmp/${VM_NAME}.xml << XMLEOF
    <!-- USB Controllers -->
    <controller type='usb' model='qemu-xhci' ports='15'/>

    <!-- Looking Glass Shared Memory -->
    <shmem name='looking-glass'>
      <model type='ivshmem-plain'/>
      <size unit='M'>${LOOKING_GLASS_SIZE}</size>
    </shmem>

    <!-- SPICE Channel (for clipboard, etc) -->
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
    </channel>

    <!-- QEMU Guest Agent -->
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>

    <!-- Input devices -->
    <input type='tablet' bus='usb'/>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>

    <!-- Balloon for memory management -->
    <memballoon model='virtio'/>

    <!-- RNG for entropy -->
    <rng model='virtio'>
      <backend model='random'>/dev/urandom</backend>
    </rng>
  </devices>

  <!-- QEMU command line additions -->
  <qemu:commandline>
    <qemu:arg value='-set'/>
    <qemu:arg value='device.hostdev0.x-pci-vendor-id=0x10de'/>
    <qemu:arg value='-set'/>
    <qemu:arg value='device.hostdev0.x-pci-device-id=0x1c8c'/>
  </qemu:commandline>
</domain>
XMLEOF

print_success "VM XML generated"

# ============================================================================
# Define and Prepare VM
# ============================================================================
print_header "Creating Virtual Machine"

# Define the VM
virsh define /tmp/${VM_NAME}.xml
print_success "VM defined: $VM_NAME"

# Save XML for reference
cp /tmp/${VM_NAME}.xml "$VM_IMAGES_DIR/${VM_NAME}.xml"
print_success "XML saved to: $VM_IMAGES_DIR/${VM_NAME}.xml"

rm /tmp/${VM_NAME}.xml

echo ""

# ============================================================================
# Summary
# ============================================================================
print_header "Setup Complete!"

echo "VM created with NVIDIA GPU passthrough!"
echo ""
echo "Configuration:"
echo "  Name:           $VM_NAME"
echo "  RAM:            8GB (huge pages enabled)"
echo "  CPUs:           4 vCPUs (pinned to cores 4-7)"
echo "  Disk:           $DISK_PATH"
echo "  GPU:            NVIDIA GTX 1050 Ti (passthrough)"
echo "  Display:        SPICE (fallback) + Looking Glass (primary)"
echo ""
echo "To start the VM:"
echo "  virsh start $VM_NAME"
echo ""
echo "To connect (initially use SPICE for Windows install):"
echo "  virt-viewer $VM_NAME"
echo ""
echo "After Windows + NVIDIA drivers installed:"
echo "  1. Install Looking Glass Host in Windows"
echo "  2. On Linux: looking-glass-client -F"
echo ""
echo -e "${YELLOW}IMPORTANT - During Windows Installation:${NC}"
echo ""
echo "1. When you see 'Where do you want to install Windows?',"
echo "   click 'Load driver' → Browse to D: or E: → amd64 → w11"
echo "   Select 'Red Hat VirtIO SCSI controller'"
echo ""
echo "2. After Windows boots, install VirtIO drivers from the CD"
echo "   Run 'virtio-win-gt-x64.msi'"
echo ""
echo "3. Download and install NVIDIA drivers from nvidia.com"
echo "   (NOT GeForce Experience - just the driver)"
echo ""
echo "4. Install Looking Glass Host from https://looking-glass.io"
echo ""
echo "5. Reboot and use Looking Glass client on Linux!"
echo ""
