#!/bin/bash
##############################################################################
# KVM/QEMU Installation Script for Fedora 42
# Installs complete virtualization stack for Windows 11 VM
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

print_header "KVM/QEMU Installation for Fedora 42"

# Check if running as root (we need sudo, not root)
if [ "$EUID" -eq 0 ]; then
    print_error "Don't run this script as root. Run as your normal user."
    exit 1
fi

# Check CPU virtualization support
echo "Checking CPU virtualization support..."
if grep -q -E "vmx|svm" /proc/cpuinfo; then
    if grep -q "vmx" /proc/cpuinfo; then
        print_success "Intel VT-x supported"
    else
        print_success "AMD-V supported"
    fi
else
    print_error "CPU virtualization not supported or not enabled in BIOS"
    echo "Please enable VT-x/AMD-V in your BIOS settings"
    exit 1
fi

echo ""

# Check if KVM module is loaded
echo "Checking KVM kernel module..."
if lsmod | grep -q kvm; then
    print_success "KVM module loaded"
else
    print_warning "KVM module not loaded, attempting to load..."
    if grep -q "vmx" /proc/cpuinfo; then
        sudo modprobe kvm_intel
    else
        sudo modprobe kvm_amd
    fi

    if lsmod | grep -q kvm; then
        print_success "KVM module loaded successfully"
    else
        print_error "Failed to load KVM module"
        exit 1
    fi
fi

echo ""

# Install virtualization packages
print_header "Installing Virtualization Packages"

echo "Installing KVM/QEMU stack..."
sudo dnf install -y \
    @virtualization \
    virt-manager \
    virt-viewer \
    libvirt-daemon-kvm \
    qemu-kvm \
    qemu-img \
    edk2-ovmf \
    swtpm \
    swtpm-tools \
    libguestfs-tools \
    virt-install \
    libvirt-client

print_success "Virtualization packages installed"

echo ""

# Install additional useful tools
echo "Installing additional tools..."
sudo dnf install -y \
    bridge-utils \
    virt-top \
    libvirt-devel \
    2>/dev/null || print_warning "Some optional packages may not be available"

echo ""

# Configure user groups
print_header "Configuring User Permissions"

CURRENT_USER=$(whoami)

# Add user to libvirt group
if groups | grep -q libvirt; then
    print_success "Already in libvirt group"
else
    sudo usermod -aG libvirt "$CURRENT_USER"
    print_success "Added $CURRENT_USER to libvirt group"
fi

# Add user to kvm group
if groups | grep -q kvm; then
    print_success "Already in kvm group"
else
    sudo usermod -aG kvm "$CURRENT_USER"
    print_success "Added $CURRENT_USER to kvm group"
fi

echo ""

# Enable and start libvirtd
print_header "Enabling libvirt Service"

sudo systemctl enable libvirtd
sudo systemctl start libvirtd

if systemctl is-active --quiet libvirtd; then
    print_success "libvirtd service is running"
else
    print_error "Failed to start libvirtd"
    exit 1
fi

echo ""

# Enable default network
echo "Configuring default network..."
if virsh net-info default &>/dev/null; then
    if virsh net-info default | grep -q "Active:.*yes"; then
        print_success "Default network already active"
    else
        sudo virsh net-start default
        print_success "Default network started"
    fi
    sudo virsh net-autostart default
    print_success "Default network set to autostart"
else
    print_warning "Default network not found, may need manual configuration"
fi

echo ""

# Validate host
print_header "Validating Virtualization Host"

echo "Running virt-host-validate..."
echo ""
virt-host-validate || true

echo ""

# Create directories
print_header "Creating Directory Structure"

VM_IMAGES_DIR="$HOME/VMs"
VM_SHARED_DIR="$HOME/vm-shared"
ISO_DIR="$HOME/ISOs"

mkdir -p "$VM_IMAGES_DIR"
mkdir -p "$VM_SHARED_DIR"
mkdir -p "$ISO_DIR"

print_success "Created $VM_IMAGES_DIR (for VM disk images)"
print_success "Created $VM_SHARED_DIR (for sharing files with VMs)"
print_success "Created $ISO_DIR (for ISO files)"

echo ""

# Summary
print_header "Installation Complete!"

echo "Installed Components:"
echo "  ✓ QEMU/KVM hypervisor"
echo "  ✓ libvirt management daemon"
echo "  ✓ virt-manager GUI"
echo "  ✓ OVMF UEFI firmware"
echo "  ✓ swtpm (TPM emulation for Windows 11)"
echo ""
echo "User Configuration:"
echo "  ✓ Added to 'libvirt' group"
echo "  ✓ Added to 'kvm' group"
echo ""
echo "Directories Created:"
echo "  $VM_IMAGES_DIR    - Store VM disk images here"
echo "  $VM_SHARED_DIR    - Share files between host and VMs"
echo "  $ISO_DIR          - Store ISO files here"
echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  IMPORTANT: Log out and log back in for group changes!    ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "After logging back in, run:"
echo "  ./02-download-resources.sh"
echo ""
