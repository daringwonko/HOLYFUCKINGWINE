#!/bin/bash
##############################################################################
# Check IOMMU Groups for GPU Passthrough
# For: Acer Nitro AN515-51 (Intel HD 630 + NVIDIA GTX 1050 Ti)
##############################################################################

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

print_header "IOMMU / GPU Passthrough Check"

echo "System: Acer Nitro AN515-51"
echo "GPUs:   Intel HD Graphics 630 (iGPU) + NVIDIA GeForce GTX 1050 Ti"
echo "VRAM:   GTX 1050 Ti has 4GB GDDR5"
echo ""

# Check if IOMMU is enabled
echo "Checking IOMMU status..."

if [ -d /sys/kernel/iommu_groups ] && [ "$(ls -A /sys/kernel/iommu_groups 2>/dev/null)" ]; then
    IOMMU_GROUPS=$(ls /sys/kernel/iommu_groups | wc -l)
    print_success "IOMMU is enabled ($IOMMU_GROUPS groups found)"
else
    print_error "IOMMU is NOT enabled"
    echo ""
    echo "To enable IOMMU, add to kernel parameters:"
    echo ""
    echo "For Intel (your CPU):"
    echo "  sudo grubby --update-kernel=ALL --args='intel_iommu=on iommu=pt'"
    echo ""
    echo "Then reboot and run this script again."
    echo ""
    exit 1
fi

echo ""

# List IOMMU groups with devices
print_header "IOMMU Groups"

echo "Looking for your GPUs..."
echo ""

shopt -s nullglob
for g in /sys/kernel/iommu_groups/*/devices/*; do
    GROUP=$(basename $(dirname $(dirname "$g")))
    DEVICE=${g##*/}
    DESC=$(lspci -nns "$DEVICE" 2>/dev/null)

    # Highlight GPUs
    if echo "$DESC" | grep -qi "VGA\|3D\|Display"; then
        if echo "$DESC" | grep -qi "NVIDIA"; then
            echo -e "${GREEN}IOMMU Group $GROUP: $DESC${NC}"
            NVIDIA_GROUP=$GROUP
        elif echo "$DESC" | grep -qi "Intel"; then
            echo -e "${BLUE}IOMMU Group $GROUP: $DESC${NC}"
            INTEL_GROUP=$GROUP
        else
            echo "IOMMU Group $GROUP: $DESC"
        fi
    fi
done

echo ""

# Check if GPUs are in separate groups
print_header "GPU Passthrough Analysis"

if [ -n "$NVIDIA_GROUP" ] && [ -n "$INTEL_GROUP" ]; then
    if [ "$NVIDIA_GROUP" != "$INTEL_GROUP" ]; then
        print_success "GPUs are in SEPARATE IOMMU groups!"
        echo ""
        echo "  Intel HD 630:      Group $INTEL_GROUP (stays with host)"
        echo "  NVIDIA GTX 1050 Ti: Group $NVIDIA_GROUP (can pass to VM)"
        echo ""
        echo "GPU passthrough should be possible!"
    else
        print_warning "GPUs are in the SAME IOMMU group ($NVIDIA_GROUP)"
        echo ""
        echo "This is common on laptops. You may need ACS override patch."
    fi
else
    print_warning "Could not identify both GPUs"
fi

echo ""

# Check what else is in NVIDIA's group
if [ -n "$NVIDIA_GROUP" ]; then
    print_header "Devices in NVIDIA's IOMMU Group ($NVIDIA_GROUP)"

    for g in /sys/kernel/iommu_groups/$NVIDIA_GROUP/devices/*; do
        DEVICE=${g##*/}
        DESC=$(lspci -nns "$DEVICE" 2>/dev/null)
        echo "  $DESC"
    done

    echo ""

    DEVICE_COUNT=$(ls /sys/kernel/iommu_groups/$NVIDIA_GROUP/devices/ | wc -l)
    if [ "$DEVICE_COUNT" -eq 1 ]; then
        print_success "NVIDIA GPU is alone in its group - ideal for passthrough!"
    elif [ "$DEVICE_COUNT" -eq 2 ]; then
        print_warning "NVIDIA GPU + 1 other device (likely audio) - usually fine"
        echo "  The NVIDIA HDMI audio controller typically passes through together."
    else
        print_warning "Multiple devices in group - may need ACS override"
    fi
fi

echo ""

# Summary and next steps
print_header "Summary"

echo "For SketchUp INSTALLATION (current goal):"
echo "  - GPU passthrough NOT needed"
echo "  - QXL virtual display is sufficient"
echo "  - Your NVIDIA GPU stays with the Linux host"
echo ""
echo "For RUNNING SketchUp in VM (future option):"
if [ -n "$NVIDIA_GROUP" ] && [ "$NVIDIA_GROUP" != "$INTEL_GROUP" ]; then
    echo "  - GPU passthrough IS possible on your system"
    echo "  - Would give VM full access to GTX 1050 Ti (4GB VRAM)"
    echo "  - Intel HD 630 would drive the host display"
    echo "  - See Arch Wiki 'PCI passthrough via OVMF' for guide"
else
    echo "  - GPU passthrough may require extra configuration"
    echo "  - Consider using Bottles on the host instead"
fi

echo ""
