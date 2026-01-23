#!/bin/bash
##############################################################################
# Create Optimized Windows 11 VM for SketchUp Installation
# Tailored for: Intel i7-7700HQ, 16GB RAM, Fedora 42
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}! $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

# Configuration - Optimized for i7-7700HQ with 16GB RAM
VM_NAME="windows11-sketchup"
VM_RAM_MB=8192          # 8GB - leaves 8GB for host
VM_CPUS=4               # 4 vCPUs - half of 8 threads
VM_DISK_GB=80           # 80GB thin-provisioned
VM_IMAGES_DIR="$HOME/VMs"
VM_SHARED_DIR="$HOME/vm-shared"
ISO_DIR="$HOME/ISOs"

print_header "Create Windows 11 VM for SketchUp"

echo "VM Configuration:"
echo "  Name:     $VM_NAME"
echo "  RAM:      ${VM_RAM_MB}MB (8GB)"
echo "  CPUs:     $VM_CPUS vCPUs"
echo "  Disk:     ${VM_DISK_GB}GB (thin-provisioned)"
echo "  Location: $VM_IMAGES_DIR/$VM_NAME.qcow2"
echo ""

# Check if libvirtd is running
if ! systemctl is-active --quiet libvirtd; then
    print_error "libvirtd is not running!"
    echo "Run: sudo systemctl start libvirtd"
    exit 1
fi
print_success "libvirtd is running"

# Check if user is in libvirt group
if ! groups | grep -q libvirt; then
    print_error "User not in libvirt group!"
    echo "Run the install script and log out/in, or run:"
    echo "  sudo usermod -aG libvirt $(whoami)"
    echo "  # Then log out and log back in"
    exit 1
fi
print_success "User is in libvirt group"

# Find Windows ISO
WIN_ISO=$(ls "$ISO_DIR"/Win11*.iso 2>/dev/null | head -1)
if [ -z "$WIN_ISO" ]; then
    WIN_ISO=$(ls "$ISO_DIR"/windows11*.iso 2>/dev/null | head -1)
fi
if [ -z "$WIN_ISO" ]; then
    WIN_ISO=$(ls "$HOME/Downloads"/Win11*.iso 2>/dev/null | head -1)
fi

if [ -z "$WIN_ISO" ]; then
    print_error "Windows 11 ISO not found!"
    echo "Please download from Microsoft and place in: $ISO_DIR/"
    echo "Run ./02-download-resources.sh for instructions"
    exit 1
fi
print_success "Found Windows ISO: $WIN_ISO"

# Find VirtIO ISO
VIRTIO_ISO="$ISO_DIR/virtio-win.iso"
if [ ! -f "$VIRTIO_ISO" ]; then
    VIRTIO_ISO=$(ls "$HOME/Downloads"/virtio-win*.iso 2>/dev/null | head -1)
fi

if [ -z "$VIRTIO_ISO" ] || [ ! -f "$VIRTIO_ISO" ]; then
    print_error "VirtIO drivers ISO not found!"
    echo "Run ./02-download-resources.sh to download"
    exit 1
fi
print_success "Found VirtIO ISO: $VIRTIO_ISO"

echo ""

# Check if VM already exists
if virsh list --all | grep -q "$VM_NAME"; then
    print_warning "VM '$VM_NAME' already exists!"
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

echo ""

# Create directories
mkdir -p "$VM_IMAGES_DIR"
mkdir -p "$VM_SHARED_DIR"

# Create disk image with metadata preallocation for better performance
print_header "Creating VM Disk Image"

DISK_PATH="$VM_IMAGES_DIR/$VM_NAME.qcow2"

echo "Creating ${VM_DISK_GB}GB thin-provisioned disk..."
qemu-img create -f qcow2 -o preallocation=metadata "$DISK_PATH" "${VM_DISK_GB}G"
print_success "Disk image created: $DISK_PATH"

ACTUAL_SIZE=$(du -h "$DISK_PATH" | cut -f1)
echo "  Initial size on disk: $ACTUAL_SIZE (will grow as used)"

echo ""

# Create the VM using virt-install
print_header "Creating Virtual Machine"

echo "This will create a UEFI-based Windows 11 VM with:"
echo "  - TPM 2.0 emulation (required for Windows 11)"
echo "  - Secure Boot enabled"
echo "  - VirtIO disk and network (high performance)"
echo "  - SPICE display (for copy/paste support)"
echo ""

virt-install \
    --name "$VM_NAME" \
    --memory "$VM_RAM_MB" \
    --vcpus "$VM_CPUS" \
    --cpu host-passthrough \
    --os-variant win11 \
    --boot uefi,loader=/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd \
    --features smm.state=on \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-tis \
    --disk path="$DISK_PATH",bus=virtio,cache=writeback,discard=unmap \
    --disk path="$VIRTIO_ISO",device=cdrom,bus=sata \
    --cdrom "$WIN_ISO" \
    --network network=default,model=virtio \
    --graphics spice,listen=none \
    --video qxl \
    --channel spicevmc,target.type=virtio,target.name=com.redhat.spice.0 \
    --channel unix,target.type=virtio,target.name=org.qemu.guest_agent.0 \
    --memballoon virtio \
    --rng /dev/urandom \
    --clock offset=localtime,rtc.tickpolicy=catchup,timer.name=hypervclock.present=yes \
    --noautoconsole \
    --wait 0

print_success "VM created successfully!"

echo ""

# Launch virt-viewer
print_header "Launching VM Console"

echo "Starting VM and opening console..."
echo ""
echo -e "${YELLOW}IMPORTANT - During Windows Installation:${NC}"
echo ""
echo "1. When you see 'Where do you want to install Windows?',"
echo "   the disk won't be visible initially."
echo ""
echo "2. Click 'Load driver' → 'Browse'"
echo ""
echo "3. Navigate to: CD Drive (D: or E:) → amd64 → w11"
echo ""
echo "4. Select 'Red Hat VirtIO SCSI controller' → Click Next"
echo ""
echo "5. The disk will now appear - proceed with installation"
echo ""
echo "6. AFTER installation, open the VirtIO CD and run:"
echo "   'virtio-win-gt-x64.msi' to install all drivers"
echo ""
echo "Press Enter to open the VM console..."
read

virt-viewer "$VM_NAME" &

echo ""
print_header "VM is Running"

echo "The VM console should now be open."
echo ""
echo "Useful commands:"
echo "  virsh console $VM_NAME     # Serial console (if enabled)"
echo "  virt-viewer $VM_NAME       # Graphical console"
echo "  virsh shutdown $VM_NAME    # Graceful shutdown"
echo "  virsh destroy $VM_NAME     # Force stop"
echo "  virsh start $VM_NAME       # Start VM"
echo ""
echo "Shared folder location (after configuring in Windows):"
echo "  $VM_SHARED_DIR"
echo ""
echo "After Windows is installed and VirtIO drivers are installed,"
echo "run the SketchUp extraction script inside Windows."
echo ""
