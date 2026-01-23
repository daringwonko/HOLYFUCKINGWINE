#!/bin/bash
##############################################################################
# Detailed IOMMU Group Analysis for GPU Passthrough
# For: Acer Nitro AN515-51 (Intel HD 630 + NVIDIA GTX 1050 Ti)
##############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}! $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${CYAN}  $1${NC}"; }

print_header "IOMMU / GPU Passthrough Analysis"

# ============================================================================
# Step 1: Check Kernel Parameters
# ============================================================================
echo -e "${BLUE}[1/5] Kernel Parameters${NC}"
echo ""

CMDLINE=$(cat /proc/cmdline)

if echo "$CMDLINE" | grep -q "intel_iommu=on"; then
    print_success "intel_iommu=on is set"
else
    print_error "intel_iommu=on NOT found in kernel parameters"
    echo ""
    echo "    Fix: sudo grubby --update-kernel=ALL --args='intel_iommu=on iommu=pt'"
    echo "    Then reboot"
    NEEDS_FIX=1
fi

if echo "$CMDLINE" | grep -q "iommu=pt"; then
    print_success "iommu=pt is set (passthrough mode)"
else
    print_warning "iommu=pt not set (optional but recommended)"
fi

echo ""

# ============================================================================
# Step 2: Check IOMMU is Active
# ============================================================================
echo -e "${BLUE}[2/5] IOMMU Status${NC}"
echo ""

if [ -d /sys/kernel/iommu_groups ] && [ "$(ls -A /sys/kernel/iommu_groups 2>/dev/null)" ]; then
    IOMMU_COUNT=$(ls /sys/kernel/iommu_groups | wc -l)
    print_success "IOMMU is active: $IOMMU_COUNT groups found"
else
    print_error "IOMMU is NOT active"
    echo ""
    echo "    Possible causes:"
    echo "    - VT-d not enabled in BIOS"
    echo "    - intel_iommu=on not in kernel parameters"
    echo "    - Reboot required after parameter change"
    exit 1
fi

# Check dmesg for IOMMU messages
if dmesg | grep -qi "DMAR.*IOMMU enabled"; then
    print_success "DMAR/IOMMU enabled in kernel messages"
fi

if dmesg | grep -qi "AMD-Vi"; then
    print_warning "AMD-Vi detected (you have Intel CPU?)"
fi

echo ""

# ============================================================================
# Step 3: Find GPUs and Their IOMMU Groups
# ============================================================================
echo -e "${BLUE}[3/5] GPU Detection${NC}"
echo ""

INTEL_GPU=""
INTEL_GROUP=""
NVIDIA_GPU=""
NVIDIA_GROUP=""
NVIDIA_AUDIO=""
NVIDIA_AUDIO_GROUP=""

shopt -s nullglob
for g in /sys/kernel/iommu_groups/*/devices/*; do
    GROUP=$(basename $(dirname $(dirname "$g")))
    DEVICE=${g##*/}
    DESC=$(lspci -nns "$DEVICE" 2>/dev/null)

    if echo "$DESC" | grep -qi "Intel.*Graphics\|Intel.*VGA"; then
        INTEL_GPU="$DEVICE"
        INTEL_GROUP="$GROUP"
        echo -e "${BLUE}Intel iGPU found:${NC}"
        print_info "Device: $DEVICE"
        print_info "IOMMU Group: $GROUP"
        print_info "$DESC"
        echo ""
    fi

    if echo "$DESC" | grep -qi "NVIDIA.*\[10de:"; then
        if echo "$DESC" | grep -qi "Audio"; then
            NVIDIA_AUDIO="$DEVICE"
            NVIDIA_AUDIO_GROUP="$GROUP"
        else
            NVIDIA_GPU="$DEVICE"
            NVIDIA_GROUP="$GROUP"
            NVIDIA_IDS=$(echo "$DESC" | grep -oP '\[10de:[0-9a-f]+\]' | tr -d '[]')
            echo -e "${GREEN}NVIDIA GPU found:${NC}"
            print_info "Device: $DEVICE"
            print_info "IOMMU Group: $GROUP"
            print_info "Device ID: $NVIDIA_IDS"
            print_info "$DESC"
            echo ""
        fi
    fi
done

if [ -n "$NVIDIA_AUDIO" ]; then
    AUDIO_IDS=$(lspci -nns "$NVIDIA_AUDIO" | grep -oP '\[10de:[0-9a-f]+\]' | tr -d '[]')
    echo -e "${GREEN}NVIDIA Audio (HDMI) found:${NC}"
    print_info "Device: $NVIDIA_AUDIO"
    print_info "IOMMU Group: $NVIDIA_AUDIO_GROUP"
    print_info "Device ID: $AUDIO_IDS"
    echo ""
fi

# ============================================================================
# Step 4: Analyze IOMMU Group Isolation
# ============================================================================
echo -e "${BLUE}[4/5] IOMMU Group Analysis${NC}"
echo ""

PASSTHROUGH_POSSIBLE=true
NEEDS_ACS=false

# Check if NVIDIA GPU is isolated
if [ -n "$NVIDIA_GROUP" ]; then
    echo "Devices in NVIDIA GPU's IOMMU Group ($NVIDIA_GROUP):"
    echo ""

    DEVICE_COUNT=0
    PROBLEM_DEVICES=""

    for g in /sys/kernel/iommu_groups/$NVIDIA_GROUP/devices/*; do
        DEVICE=${g##*/}
        DESC=$(lspci -nns "$DEVICE" 2>/dev/null)
        DEVICE_COUNT=$((DEVICE_COUNT + 1))

        if echo "$DESC" | grep -qi "NVIDIA"; then
            echo -e "    ${GREEN}$DESC${NC}"
        elif echo "$DESC" | grep -qi "bridge\|host"; then
            echo -e "    ${YELLOW}$DESC${NC}"
            # Bridges are usually OK if they're PCIe root/switch
        else
            echo -e "    ${RED}$DESC${NC}"
            PROBLEM_DEVICES="$PROBLEM_DEVICES\n    - $DESC"
            PASSTHROUGH_POSSIBLE=false
        fi
    done

    echo ""

    if [ "$DEVICE_COUNT" -eq 1 ]; then
        print_success "NVIDIA GPU is ALONE in its IOMMU group - IDEAL!"
    elif [ "$DEVICE_COUNT" -eq 2 ] && [ "$NVIDIA_GROUP" = "$NVIDIA_AUDIO_GROUP" ]; then
        print_success "NVIDIA GPU + Audio are together - This is normal and fine"
    elif [ "$PASSTHROUGH_POSSIBLE" = true ]; then
        print_warning "Multiple devices, but only GPU-related - should work"
    else
        print_error "Non-GPU devices in the same group!"
        echo -e "$PROBLEM_DEVICES"
        echo ""
        echo "    These devices would also be passed to VM, which may break the host."
        NEEDS_ACS=true
    fi
else
    print_error "NVIDIA GPU not found!"
    exit 1
fi

echo ""

# Check if Intel and NVIDIA are in different groups
if [ -n "$INTEL_GROUP" ] && [ -n "$NVIDIA_GROUP" ]; then
    if [ "$INTEL_GROUP" = "$NVIDIA_GROUP" ]; then
        print_error "Intel and NVIDIA GPUs are in the SAME IOMMU group!"
        echo ""
        echo "    This is a problem - you can't keep Intel for host while passing NVIDIA."
        echo "    This is common on some laptops with poor IOMMU isolation."
        NEEDS_ACS=true
        PASSTHROUGH_POSSIBLE=false
    else
        print_success "Intel (Group $INTEL_GROUP) and NVIDIA (Group $NVIDIA_GROUP) are SEPARATE"
    fi
fi

echo ""

# ============================================================================
# Step 5: Current Driver Binding
# ============================================================================
echo -e "${BLUE}[5/5] Driver Binding Status${NC}"
echo ""

if [ -n "$NVIDIA_GPU" ]; then
    NVIDIA_DRIVER=$(lspci -nnk -s "$NVIDIA_GPU" | grep "Kernel driver" | awk '{print $NF}')

    if [ "$NVIDIA_DRIVER" = "vfio-pci" ]; then
        print_success "NVIDIA GPU is bound to vfio-pci - Ready for passthrough!"
    elif [ "$NVIDIA_DRIVER" = "nvidia" ]; then
        print_warning "NVIDIA GPU is bound to 'nvidia' driver"
        echo "    You need to configure vfio-pci to claim it at boot"
    elif [ "$NVIDIA_DRIVER" = "nouveau" ]; then
        print_warning "NVIDIA GPU is bound to 'nouveau' driver"
        echo "    You need to blacklist nouveau and bind to vfio-pci"
    elif [ -z "$NVIDIA_DRIVER" ]; then
        print_warning "NVIDIA GPU has no driver bound"
        echo "    This might be OK if vfio-pci will claim it"
    else
        print_info "NVIDIA GPU bound to: $NVIDIA_DRIVER"
    fi
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
print_header "Summary & Recommendations"

if [ "$PASSTHROUGH_POSSIBLE" = true ]; then
    echo -e "${GREEN}GPU PASSTHROUGH APPEARS POSSIBLE ON YOUR SYSTEM${NC}"
    echo ""
    echo "Next steps:"
    echo ""

    if [ "$NVIDIA_DRIVER" != "vfio-pci" ]; then
        GPU_ID=$(lspci -nn -s "$NVIDIA_GPU" | grep -oP '\[10de:[0-9a-f]+\]' | tr -d '[]')
        if [ -n "$NVIDIA_AUDIO" ]; then
            AUDIO_ID=$(lspci -nn -s "$NVIDIA_AUDIO" | grep -oP '\[10de:[0-9a-f]+\]' | tr -d '[]')
            echo "1. Configure vfio-pci to claim GPU at boot:"
            echo ""
            echo "   sudo tee /etc/modprobe.d/vfio.conf << EOF"
            echo "   options vfio-pci ids=$GPU_ID,$AUDIO_ID"
            echo "   softdep nvidia pre: vfio-pci"
            echo "   softdep nouveau pre: vfio-pci"
            echo "   EOF"
        else
            echo "1. Configure vfio-pci to claim GPU at boot:"
            echo ""
            echo "   sudo tee /etc/modprobe.d/vfio.conf << EOF"
            echo "   options vfio-pci ids=$GPU_ID"
            echo "   softdep nvidia pre: vfio-pci"
            echo "   softdep nouveau pre: vfio-pci"
            echo "   EOF"
        fi
        echo ""
        echo "2. Add vfio to initramfs:"
        echo ""
        echo "   sudo tee /etc/dracut.conf.d/vfio.conf << EOF"
        echo '   add_drivers+=" vfio vfio_iommu_type1 vfio_pci "'
        echo "   EOF"
        echo ""
        echo "3. Rebuild initramfs and reboot:"
        echo ""
        echo "   sudo dracut -f && sudo reboot"
        echo ""
        echo "4. After reboot, run this script again to verify vfio-pci binding"
    else
        echo "1. Your GPU is already bound to vfio-pci!"
        echo ""
        echo "2. Create VM with GPU passthrough:"
        echo "   ./04-create-vm-gpu-passthrough.sh"
    fi
else
    echo -e "${RED}GPU PASSTHROUGH HAS COMPLICATIONS${NC}"
    echo ""

    if [ "$NEEDS_ACS" = true ]; then
        echo "Your IOMMU groups are not ideally separated."
        echo ""
        echo "Options:"
        echo ""
        echo "1. Check BIOS for IOMMU/ACS settings"
        echo "   - Some BIOS have hidden ACS settings"
        echo "   - Try updating BIOS"
        echo ""
        echo "2. Use ACS Override Patch (security tradeoff)"
        echo "   - Requires custom kernel or kernel parameter"
        echo "   - Add 'pcie_acs_override=downstream,multifunction' to kernel"
        echo ""
        echo "3. Use Looking Glass without full passthrough"
        echo "   - Less isolation, but can still work"
        echo ""
        echo "4. Accept and try anyway"
        echo "   - May work depending on what other devices are in the group"
    fi
fi

echo ""

# Output for scripts
if [ -n "$NVIDIA_GPU" ]; then
    echo "---"
    echo "For scripting:"
    echo "  NVIDIA_GPU_BDF=$NVIDIA_GPU"
    echo "  NVIDIA_GROUP=$NVIDIA_GROUP"
    [ -n "$NVIDIA_IDS" ] && echo "  NVIDIA_IDS=$NVIDIA_IDS"
    [ -n "$NVIDIA_AUDIO" ] && echo "  NVIDIA_AUDIO_BDF=$NVIDIA_AUDIO"
    [ -n "$AUDIO_IDS" ] && echo "  NVIDIA_AUDIO_IDS=$AUDIO_IDS"
fi
