# Transfer Guide - Moving Setup from VM to Local Fedora 42 System

This guide explains how to transfer the SketchUp 2026 Wine setup from this VM to your actual Fedora 42 Acer Nitro laptop.

---

## Overview

You have three components to transfer:

1. **Scripts & Documentation** (`~/sketchup-wine-setup/`)
2. **Wine Prefix** (`~/.wine/sketchup2026/`)
3. **SketchUp Installer** (already on your system at `/home/tomas/SketchUp 2026/`)

---

## Step 1: Prepare Files for Transfer (On This VM)

### Archive the Setup Package

```bash
# Go to home directory
cd ~

# Create archive of all scripts and documentation
tar -czf sketchup-wine-setup.tar.gz sketchup-wine-setup/

# Create archive of the Wine prefix (configured environment)
tar -czf sketchup2026-prefix.tar.gz .wine/sketchup2026/

# Verify archives were created
ls -lh sketchup-*.tar.gz
# Should see two files, each several hundred MB
```

### Alternative: Create Smaller Archives (If Transfer is Slow)

If your internet is slow, split the prefix into smaller chunks:

```bash
# Split prefix into 500MB chunks
tar -czf - .wine/sketchup2026/ | split -b 500m - sketchup2026-prefix.tar.gz.

# This creates: sketchup2026-prefix.tar.gz.aa, .ab, .ac, etc.

# Verify
ls -lh sketchup2026-prefix.tar.gz.*
```

---

## Step 2: Transfer Files to Your Laptop

### Option A: USB Drive

```bash
# On VM:
cp sketchup-*.tar.gz /mnt/usb/

# Then physically transfer USB to laptop
```

### Option B: Cloud Storage

```bash
# On VM: Upload to cloud service
cp sketchup-*.tar.gz ~/Downloads/  # Or your cloud folder
# Use: Google Drive, Dropbox, OneDrive, etc.

# On Laptop: Download from cloud
```

### Option C: Network Transfer (SCP)

```bash
# On VM: Transfer via SSH/SCP
scp sketchup-*.tar.gz user@laptop-ip:~/Downloads/
# Example: scp sketchup-*.tar.gz tomas@192.168.1.100:~/

# Then on Laptop:
cd ~/Downloads
ls sketchup-*.tar.gz
```

### Option D: Direct Download (If VM is Accessible)

```bash
# On VM: Start simple HTTP server
cd ~
python3 -m http.server 8000

# On Laptop: Download via browser
# Visit: http://vm-ip:8000/
# Or via wget:
# wget http://vm-ip:8000/sketchup-wine-setup.tar.gz
```

---

## Step 3: Verify Transfer Integrity (On Your Laptop)

### Check File Sizes

```bash
# On laptop, verify files arrived completely:
ls -lh ~/Downloads/sketchup-*.tar.gz

# Compare with original sizes from VM:
# (Should match or be very close)
```

### Verify with Checksums

For extra security, verify file integrity:

```bash
# On VM: Create checksum
sha256sum sketchup-*.tar.gz > sketchup-checksums.sha256

# Transfer the checksum file too
# scp sketchup-checksums.sha256 tomas@laptop:~/Downloads/

# On laptop: Verify
cd ~/Downloads
sha256sum -c sketchup-checksums.sha256

# Should show:
# sketchup-wine-setup.tar.gz: OK
# sketchup2026-prefix.tar.gz: OK
```

---

## Step 4: Extract Files on Your Laptop

### Extract Setup Scripts and Documentation

```bash
# On laptop, in home directory:
cd ~
tar -xzf ~/Downloads/sketchup-wine-setup.tar.gz

# Verify
ls -la ~/sketchup-wine-setup/

# Should show: scripts/, docs/, config/, QUICKSTART.md
```

### Extract Wine Prefix

```bash
# On laptop:
cd ~
tar -xzf ~/Downloads/sketchup2026-prefix.tar.gz

# This extracts to: ~/.wine/sketchup2026/
# Verify
ls -la ~/.wine/sketchup2026/

# Should show: drive_c/, dosdevices/, system.reg, user.reg, etc.
```

### If You Split the Prefix Into Chunks

```bash
# On laptop: Recombine chunks
cd ~/Downloads
cat sketchup2026-prefix.tar.gz.* | tar -xzf -

# This extracts everything to ~/.wine/sketchup2026/
```

---

## Step 5: Make Scripts Executable

```bash
# On laptop:
chmod +x ~/sketchup-wine-setup/scripts/*.sh

# Verify
ls -l ~/sketchup-wine-setup/scripts/

# All .sh files should have 'x' (executable) marker
```

---

## Step 6: Verify WineHQ Installation on Laptop

Before launching, ensure Wine is installed on your laptop:

```bash
# Check if Wine is already installed
wine --version

# If not installed, run:
cd ~/sketchup-wine-setup/scripts
sudo ./01-install-winehq.sh

# If that fails, use COPR:
sudo dnf copr enable sentry/wine
sudo dnf install wine
```

---

## Step 7: Quick Verification Test

Test that the transferred setup works:

```bash
# Test 1: Verify prefix structure
file ~/.wine/sketchup2026/system.reg
# Should show: "MS Windows registry file"

# Test 2: List installed components
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks list-installed | head -10
# Should show components like dotnet48, vcrun2017, etc.

# Test 3: Verify GPU offloading setup
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep renderer
# Should show: NVIDIA GeForce GTX 1050 Ti

# Test 4: Test Wine works
wine --version
# Should show: Wine 10.0 or 9.0
```

---

## Step 8: Launch SketchUp

Once verified, launch SketchUp:

```bash
# Simple method:
~/sketchup-wine-setup/scripts/03-launch-sketchup.sh

# Or with debug output if issues:
export WINEDEBUG=+all
~/sketchup-wine-setup/scripts/03-launch-sketchup.sh 2>&1 | head -50
```

---

## Troubleshooting Transfer Issues

### Problem: Archive Extraction Fails

**Symptom:**
```
tar: Unexpected end of file
tar: Error is not recoverable
```

**Causes:**
- Incomplete download
- Corrupted transfer

**Solutions:**

```bash
# Verify file integrity
tar -tzf ~/Downloads/sketchup-wine-setup.tar.gz | head

# If that fails, re-download the file

# For split files, check all chunks exist:
ls -la sketchup2026-prefix.tar.gz.*
# Should have all chunks (.aa, .ab, .ac, etc.)
```

### Problem: "Wine Prefix Not Found"

**Symptom:**
```
ERROR: ~/.wine/sketchup2026 not found
```

**Solution:**

```bash
# Verify extraction path
ls -la ~/.wine/

# If sketchup2026 doesn't exist:
cd ~
tar -xzf ~/Downloads/sketchup2026-prefix.tar.gz

# Or manually extract with path:
tar -xzf ~/Downloads/sketchup2026-prefix.tar.gz -C ~/
```

### Problem: Scripts Won't Execute

**Symptom:**
```
./03-launch-sketchup.sh: Permission denied
```

**Solution:**

```bash
# Make scripts executable
chmod +x ~/sketchup-wine-setup/scripts/*.sh

# Verify
ls -l ~/sketchup-wine-setup/scripts/00-master-setup.sh
# Should show: -rwxr-xr-x (with 'x' markers)
```

### Problem: Wine Prefix is Incomplete/Corrupted

**Symptom:**
```
wine: failed to initialize wineprefix
Error: Cannot open /registry at /home/user/.wine/sketchup2026
```

**Solutions:**

1. **Re-extract prefix from backup:**
   ```bash
   rm -rf ~/.wine/sketchup2026/
   cd ~
   tar -xzf ~/Downloads/sketchup2026-prefix.tar.gz
   ```

2. **If backup is corrupted, rebuild from scratch:**
   ```bash
   rm -rf ~/.wine/sketchup2026/
   ~/sketchup-wine-setup/scripts/02-setup-wineprefix.sh
   # This takes 15-20 minutes but ensures a fresh, good prefix
   ```

---

## Keeping Backups

### On Your Laptop: Keep the Archives

```bash
# Don't delete the archives - keep them as backup
mkdir -p ~/backups
cp ~/Downloads/sketchup-*.tar.gz ~/backups/

# If prefix gets corrupted later, you can restore:
rm -rf ~/.wine/sketchup2026/
tar -xzf ~/backups/sketchup2026-prefix.tar.gz -C ~/
```

### Create Additional Backups

```bash
# Backup current working prefix
tar -czf ~/backups/sketchup2026-working-backup-$(date +%Y%m%d).tar.gz ~/.wine/sketchup2026/

# List backups
ls -lh ~/backups/sketchup2026-*.tar.gz
```

---

## Using SketchUp on Laptop

### Standard Launch

```bash
~/sketchup-wine-setup/scripts/03-launch-sketchup.sh
```

### Create Desktop Shortcut (GNOME)

```bash
# Create .desktop file
cat > ~/.local/share/applications/sketchup2026.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=SketchUp 2026
Comment=3D Modeling with GPU Acceleration
Exec=/home/tomas/sketchup-wine-setup/scripts/03-launch-sketchup.sh
Icon=application-x-ms-dos-executable
Terminal=false
Categories=Graphics;3DGraphics;
EOF

# Make it executable
chmod +x ~/.local/share/applications/sketchup2026.desktop

# Now SketchUp appears in your Applications menu
```

### Create Bash Alias

```bash
# Add to ~/.bashrc
echo 'alias sketchup="~/sketchup-wine-setup/scripts/03-launch-sketchup.sh"' >> ~/.bashrc

# Reload shell
source ~/.bashrc

# Now just type: sketchup
```

---

## Updating Components (On Laptop)

If you need to update Wine or dependencies later:

```bash
# Update WineHQ
sudo dnf update wine

# Update dependencies
export WINEPREFIX="$HOME/.wine/sketchup2026"
winetricks dxvk vkd3d --force

# Update Vulkan drivers
sudo dnf update vulkan-loader lib32-vulkan-loader
```

---

## Transferring Back to VM (Optional)

If you make changes on your laptop and want to transfer back:

```bash
# On laptop: Archive the updated prefix
cd ~
tar -czf sketchup2026-prefix-updated.tar.gz .wine/sketchup2026/

# Transfer to VM
# scp sketchup2026-prefix-updated.tar.gz user@vm:~/

# On VM: Extract and replace
tar -xzf sketchup2026-prefix-updated.tar.gz
# Existing ~/.wine/sketchup2026/ will be overwritten
```

---

## File Size Reference

For planning your transfer:

```
sketchup-wine-setup.tar.gz:  50-100 MB (scripts & docs)
sketchup2026-prefix.tar.gz:  800 MB - 1.2 GB (Wine prefix)

Total: ~1-1.3 GB
```

If using USB or cloud storage, ensure you have enough space.

---

## Final Checklist

Before considering transfer complete:

- [ ] Archives downloaded to laptop
- [ ] Checksums verified (optional but recommended)
- [ ] Archives extracted to correct locations
- [ ] Scripts made executable
- [ ] Wine is installed on laptop
- [ ] GPU offloading verified (`glxinfo` test)
- [ ] SketchUp launches successfully
- [ ] Trimble login screen appears
- [ ] Backup archives kept in safe location

---

## Quick Troubleshooting Reference

| Issue | Command |
|-------|---------|
| Check extraction | `file ~/.wine/sketchup2026/system.reg` |
| List components | `export WINEPREFIX="$HOME/.wine/sketchup2026"; winetricks list-installed` |
| Test GPU offload | `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo \| grep renderer` |
| Test Wine | `wine --version` |
| Launch SketchUp | `~/sketchup-wine-setup/scripts/03-launch-sketchup.sh` |
| Check file integrity | `tar -tzf sketchup-wine-setup.tar.gz \| head` |

---

**You're now ready to transfer your SketchUp 2026 Wine setup to your Fedora 42 laptop!**

All the configuration is done. When you download the archives and extract them, another LLM (or you) can immediately launch SketchUp without any additional setup.

For any issues on the laptop, refer to:
- `~/sketchup-wine-setup/docs/README.md` - Full guide
- `~/sketchup-wine-setup/docs/TROUBLESHOOTING.md` - Problem solving
- `~/sketchup-wine-setup/QUICKSTART.md` - Quick reference
