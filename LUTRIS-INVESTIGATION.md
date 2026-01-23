# Lutris Investigation Guide

## What is Lutris?

**Lutris** is an open-source game manager for Linux that provides:
- Curated Wine/Proton runners with specific patches
- Community-submitted install scripts for Windows applications
- Automatic dependency management
- Per-application Wine prefix isolation

**Website:** https://lutris.net

## Why Lutris Might Help

Lutris maintains its own Wine builds (`wine-ge`, `wine-lutris`) that include patches not in upstream Wine or even Proton. Some of these patches address:
- Installer compatibility issues
- DRM bypasses
- Application-specific fixes

Additionally, someone may have already created a working SketchUp install script.

---

## Investigation Steps

### Step 1: Check for Existing SketchUp Scripts

Search the Lutris database for SketchUp:

```bash
# Web search
xdg-open "https://lutris.net/games?q=sketchup"
```

Or via Lutris app:
1. Open Lutris
2. Click "Search Lutris.net" (magnifying glass icon)
3. Search for "SketchUp"
4. Check if any scripts exist for SketchUp 2024, 2025, or 2026

**What to look for:**
- Install scripts with recent activity
- Comments indicating success/failure
- Wine version recommendations

### Step 2: Install Lutris

```bash
# Fedora
sudo dnf install lutris

# Or via Flatpak
flatpak install flathub net.lutris.Lutris
```

### Step 3: Install Wine-GE Runner

Wine-GE (GloriousEggroll) includes many compatibility patches:

1. Open Lutris
2. Click hamburger menu (☰) → Preferences
3. Go to "Runners" tab
4. Find "Wine" and click the manage button (folder icon)
5. Install latest `wine-ge-proton` or `wine-ge-lol` version

### Step 4: Create Manual SketchUp Configuration

If no existing script works, create a manual configuration:

1. Click "+" (Add Game) in Lutris
2. Select "Add locally installed game"
3. Configure:
   - **Name:** SketchUp 2026
   - **Runner:** Wine
   - **Wine prefix:** (create new, e.g., `~/.local/share/lutris/prefixes/sketchup2026`)
   - **Architecture:** 64-bit

4. In "Runner options":
   - **Wine version:** wine-ge-proton-8-26 (or latest)
   - **DXVK:** Enabled
   - **VKD3D:** Enabled
   - **Windows version:** Windows 10

5. In "System options":
   - Enable "Show advanced options"
   - Add environment variables:
     ```
     __NV_PRIME_RENDER_OFFLOAD=1
     __GLX_VENDOR_LIBRARY_NAME=nvidia
     VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
     ```

### Step 5: Install Dependencies via Winetricks

Right-click the game entry → Winetricks:
- Select and install: `dotnet48`, `vcrun2017`, `corefonts`
- For WebView2: May need manual installation

### Step 6: Try Installation

1. Right-click SketchUp entry → "Run EXE inside Wine prefix"
2. Select `SketchUp-2026-x-xxx-xx.exe`
3. Watch for different behavior compared to Bottles

---

## Lutris-Specific Wine Runners to Try

| Runner | Description | Try If... |
|--------|-------------|-----------|
| `wine-ge-proton-8-26` | Latest GE with Proton patches | Default choice |
| `wine-ge-lol-8-26` | GE with League of Legends fixes | Has anti-cheat bypasses |
| `lutris-fshack-7.2` | Lutris build with FullScreen Hack | Display issues |
| `wine-staging-9.0` | Staging patches | Installer-specific fixes |

### Installing Runners

```bash
# Via Lutris GUI (recommended)
# Preferences → Runners → Wine → Manage versions

# Or download directly
cd ~/.local/share/lutris/runners/wine/
wget https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-26/wine-lutris-GE-Proton8-26-x86_64.tar.xz
tar -xf wine-lutris-GE-Proton8-26-x86_64.tar.xz
```

---

## Community Resources

### Lutris Discord
Join the Lutris Discord server for real-time help:
- Server: https://discord.gg/Pnt5CuY
- Ask in `#lutris-support` channel
- Include your debug logs

### Wine AppDB
Check if anyone has documented SketchUp:
```bash
xdg-open "https://appdb.winehq.org/objectManager.php?sClass=application&sTitle=SketchUp"
```

### ProtonDB (Indirect)
While Proton is for Steam, ProtonDB comments sometimes include Wine tips:
```bash
xdg-open "https://www.protondb.com/search?q=sketchup"
```

### Reddit Communities
- r/linux_gaming
- r/wine_gaming
- Search: "SketchUp Wine" or "SketchUp Lutris"

---

## Creating a Lutris Install Script

If you get SketchUp working, consider contributing back:

### Script Template

```yaml
name: SketchUp 2026
game_slug: sketchup-2026
version: Installer
slug: sketchup-2026-installer
runner: wine

script:
  files:
  - installer: N/A:Select SketchUp 2026 installer

  wine:
    version: wine-ge-proton-8-26
    dxvk: true
    vkd3d: true

  installer:
  - task:
      name: create_prefix
      prefix: $GAMEDIR/prefix
      arch: win64

  - task:
      name: winetricks
      prefix: $GAMEDIR/prefix
      app: dotnet48 vcrun2017 corefonts

  - task:
      name: wineexec
      prefix: $GAMEDIR/prefix
      executable: $installer

  - task:
      name: set_regedit
      prefix: $GAMEDIR/prefix
      path: HKEY_CURRENT_USER\Software\Wine\Direct3D
      key: MaxVersionGL
      value: "4"
      type: REG_DWORD

  game:
    exe: drive_c/Program Files/SketchUp/SketchUp 2026/SketchUp.exe
    prefix: $GAMEDIR/prefix

  system:
    env:
      __NV_PRIME_RENDER_OFFLOAD: "1"
      __GLX_VENDOR_LIBRARY_NAME: nvidia
```

### Submitting Script

1. Test thoroughly
2. Go to https://lutris.net/games/sketchup-2026/ (create if needed)
3. Click "Submit Installer"
4. Paste your YAML script
5. Add notes about requirements and known issues

---

## Success Probability: ~20%

**Why relatively low:**
- Same underlying Wine limitation (WUA COM interfaces)
- Wine-GE patches focus on games, not professional software
- InstallShield 2024 is too new for existing workarounds

**But worth trying because:**
- Different Wine build might have relevant patches
- Community may have solved this already
- Good learning experience for Wine debugging
- If Windows VM extraction works, Lutris is a good launcher

---

## Quick Checklist

- [ ] Search Lutris.net for existing SketchUp scripts
- [ ] Install Lutris (Flatpak or DNF)
- [ ] Install wine-ge-proton runner
- [ ] Create SketchUp game entry with proper settings
- [ ] Install dependencies via Winetricks
- [ ] Attempt installer with WINEDEBUG enabled
- [ ] Try alternative runners if first fails
- [ ] Check Lutris Discord for advice
- [ ] Search WineHQ AppDB
- [ ] If Windows extraction works, configure as locally installed game

---

*Document created: 2026-01-23*
*Part of HOLYFUCKINGWINE debugging toolkit*
