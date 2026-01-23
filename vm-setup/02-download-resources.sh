#!/bin/bash
##############################################################################
# Download Resources for Windows 11 VM
# Downloads VirtIO drivers and provides Windows 11 ISO instructions
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

ISO_DIR="$HOME/ISOs"
mkdir -p "$ISO_DIR"

print_header "Download Resources for Windows 11 VM"

# Download VirtIO drivers
echo "Downloading VirtIO Windows drivers..."
echo "This provides high-performance paravirtualized drivers for:"
echo "  - Storage (virtio-blk/scsi)"
echo "  - Network (virtio-net)"
echo "  - Memory balloon"
echo "  - Display (QXL)"
echo ""

VIRTIO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
VIRTIO_ISO="$ISO_DIR/virtio-win.iso"

if [ -f "$VIRTIO_ISO" ]; then
    print_warning "VirtIO ISO already exists: $VIRTIO_ISO"
    read -p "Re-download? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_success "Keeping existing VirtIO ISO"
    else
        rm "$VIRTIO_ISO"
    fi
fi

if [ ! -f "$VIRTIO_ISO" ]; then
    echo "Downloading from: $VIRTIO_URL"
    wget -O "$VIRTIO_ISO" "$VIRTIO_URL"
    print_success "VirtIO drivers downloaded: $VIRTIO_ISO"
else
    print_success "VirtIO ISO ready: $VIRTIO_ISO"
fi

echo ""

# Windows 11 ISO instructions
print_header "Windows 11 ISO"

WIN11_ISO="$ISO_DIR/Win11*.iso"
FOUND_ISO=$(ls $WIN11_ISO 2>/dev/null | head -1)

if [ -n "$FOUND_ISO" ]; then
    print_success "Found Windows 11 ISO: $FOUND_ISO"
else
    echo -e "${YELLOW}Windows 11 ISO not found in $ISO_DIR${NC}"
    echo ""
    echo "To download Windows 11:"
    echo ""
    echo "  1. Open: https://www.microsoft.com/software-download/windows11"
    echo ""
    echo "  2. Scroll to 'Download Windows 11 Disk Image (ISO)'"
    echo ""
    echo "  3. Select 'Windows 11 (multi-edition ISO for x64 devices)'"
    echo ""
    echo "  4. Click 'Download Now'"
    echo ""
    echo "  5. Select your language and click 'Confirm'"
    echo ""
    echo "  6. Click '64-bit Download'"
    echo ""
    echo "  7. Save the ISO to: $ISO_DIR/"
    echo ""
    echo ""
    echo "Alternatively, use the direct download helper:"
    echo ""
    echo "  # Using Firefox (recommended)"
    echo "  firefox 'https://www.microsoft.com/software-download/windows11' &"
    echo ""

    read -p "Open download page in browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open "https://www.microsoft.com/software-download/windows11" 2>/dev/null &
        echo ""
        echo "Browser opened. Download the ISO and save it to:"
        echo "  $ISO_DIR/"
        echo ""
    fi
fi

echo ""

# Check disk space
print_header "Disk Space Check"

AVAILABLE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
REQUIRED=80

echo "Available space in $HOME: ${AVAILABLE}GB"
echo "Required for VM (disk + overhead): ~${REQUIRED}GB"
echo ""

if [ "$AVAILABLE" -lt "$REQUIRED" ]; then
    print_warning "Low disk space! You may need to free up space."
    echo "The Windows VM disk image will be ~60GB when fully used."
else
    print_success "Sufficient disk space available"
fi

echo ""

# Summary
print_header "Resource Status"

echo "VirtIO Drivers:"
if [ -f "$VIRTIO_ISO" ]; then
    SIZE=$(du -h "$VIRTIO_ISO" | cut -f1)
    echo -e "  ${GREEN}✓${NC} $VIRTIO_ISO ($SIZE)"
else
    echo -e "  ${RED}✗${NC} Not downloaded"
fi

echo ""
echo "Windows 11 ISO:"
FOUND_ISO=$(ls $ISO_DIR/Win11*.iso 2>/dev/null | head -1)
if [ -n "$FOUND_ISO" ]; then
    SIZE=$(du -h "$FOUND_ISO" | cut -f1)
    echo -e "  ${GREEN}✓${NC} $FOUND_ISO ($SIZE)"
else
    echo -e "  ${YELLOW}!${NC} Not found - download from Microsoft"
fi

echo ""

# Next steps
if [ -f "$VIRTIO_ISO" ] && [ -n "$FOUND_ISO" ]; then
    print_success "All resources ready!"
    echo ""
    echo "Next step:"
    echo "  ./03-create-windows-vm.sh"
else
    print_warning "Download Windows 11 ISO before proceeding"
    echo ""
    echo "Once downloaded, run:"
    echo "  ./03-create-windows-vm.sh"
fi

echo ""
