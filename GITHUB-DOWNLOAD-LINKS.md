# Direct Download Links for Required Packages

Click these links to go directly to the GitHub repository or official source. Download manually via your browser.

---

## 1. Winetricks (Script Manager)
**GitHub Repository:**
https://github.com/Winetricks/winetricks

**Direct Link to Latest Script:**
https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks

**Save as:** `winetricks` (no extension)
**Size:** ~100 KB
**Purpose:** Manages Wine components (dotnet, vc runtime, webview2, etc.)

---

## 2. DXVK (DirectX 10/11/12 to Vulkan)
**GitHub Repository:**
https://github.com/doitsujin/dxvk

**Releases Page:**
https://github.com/doitsujin/dxvk/releases

**Download:** Look for latest release, download `dxvk-x.xx.tar.gz` (not the source code ZIP)
**Size:** ~100-150 MB per release
**Purpose:** Translates DirectX to Vulkan for GPU acceleration
**Note:** Extract after download, run setup script

---

## 3. VKD3D-Proton (Direct3D 12 Support)
**GitHub Repository:**
https://github.com/HansKristian-Work/vkd3d-proton

**Releases Page:**
https://github.com/HansKristian-Work/vkd3d-proton/releases

**Download:** Look for latest release, download `vkd3d-proton-x.x.tar.zst` or `.tar.gz`
**Size:** ~50-100 MB
**Purpose:** Direct3D 12 support for modern graphics via Vulkan
**Note:** Extract after download

---

## 4. Wine Stable 10.0 (WineHQ - NOT GitHub)
**Official Download Page:**
https://wiki.winehq.org/Download

**Direct RPM Links for Fedora 42:**
- https://dl.winehq.org/wine-builds/fedora/42/wine-stable-10.0-1.fc42.x86_64.rpm
- https://dl.winehq.org/wine-builds/fedora/42/wine-stable-10.0-1.fc42.i686.rpm
- https://dl.winehq.org/wine-builds/fedora/42/wine-common-10.0-1.fc42.noarch.rpm

**Size:** ~400-500 MB total for all 3
**Purpose:** Windows compatibility layer

---

## 5. .NET Framework 4.8 (Required for SketchUp)
**Microsoft Official Download:**
https://dotnet.microsoft.com/en-us/download/dotnet-framework/net48

**Direct Offline Installer:**
https://download.microsoft.com/download/7/0/3/703455ee-a747-4cc8-bd3e-98a615c3aaab/NDP48-x86-x64-AllOS-ENU.exe

**Size:** ~120 MB
**Purpose:** .NET Framework runtime - CRITICAL for SketchUp
**Filename:** `NDP48-x86-x64-AllOS-ENU.exe`

---

## 6. Visual C++ 2017 Redistributable (Runtime)
**Microsoft Official Download:**
https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads

**Direct Download (x86):**
https://aka.ms/vs/15/release/vc_redist.x86.exe

**Direct Download (x64):**
https://aka.ms/vs/15/release/vc_redist.x64.exe

**Size:** ~14 MB each
**Purpose:** Visual C++ runtime dependencies
**Filenames:** `vc_redist.x86.exe`, `vc_redist.x64.exe`

---

## 7. WebView2 (Trimble Identity Login - CRITICAL)
**Microsoft Official Download:**
https://developer.microsoft.com/en-us/microsoft-edge/webview2/

**Standalone Installer (x64):**
https://go.microsoft.com/fwlink/p/?LinkId=2124703

**Standalone Installer (x86):**
https://go.microsoft.com/fwlink/p/?LinkId=2124703 (Microsoft provides universal installer)

**Size:** ~130 MB
**Purpose:** WebView2 runtime for Trimble login - CRITICAL
**Note:** This is the one most likely to be firewall-blocked. Download manually.

---

## Alternative: If GitHub Links Change
If any repository has moved, search for:
- `Winetricks winetricks` on GitHub
- `doitsujin dxvk` on GitHub
- `HansKristian-Work vkd3d-proton` on GitHub

---

## Recommended Download Order

1. **Winetricks script** - Save to `packages/tools/`
2. **Wine RPMs** - Download all 3, save to `packages/wine/`
3. **DXVK** - Extract to `packages/winetricks-components/dxvk/`
4. **VKD3D-Proton** - Extract to `packages/winetricks-components/vkd3d/`
5. **WebView2** - Will be installed automatically during setup

---

## Total Download Size (COMPLETE LIST)
- Winetricks: ~100 KB
- Wine RPMs: ~400-500 MB
- DXVK: ~100-150 MB
- VKD3D-Proton: ~50-100 MB
- .NET Framework 4.8: ~120 MB
- Visual C++ 2017 (both): ~28 MB
- WebView2: ~130 MB
- **TOTAL: ~830-1030 MB**

---

## Complete File Checklist (What You Actually Need to Download)

**To be saved in `packages/tools/`:**
- [ ] winetricks (script, no extension)

**To be saved in `packages/wine/`:**
- [ ] wine-stable-10.0-1.fc42.x86_64.rpm
- [ ] wine-stable-10.0-1.fc42.i686.rpm
- [ ] wine-common-10.0-1.fc42.noarch.rpm

**To be saved in `packages/winetricks-components/dxvk/`:**
- [ ] dxvk-x.xx.tar.gz (extracted)

**To be saved in `packages/winetricks-components/vkd3d/`:**
- [ ] vkd3d-proton-x.x.tar.gz or .tar.zst (extracted)

**To be saved in `packages/winetricks-components/dotnet48/`:**
- [ ] NDP48-x86-x64-AllOS-ENU.exe

**To be saved in `packages/winetricks-components/vcrun2017/`:**
- [ ] vc_redist.x86.exe
- [ ] vc_redist.x64.exe

**To be saved in `packages/winetricks-components/webview2/`:**
- [ ] WebView2 installer (from Microsoft download link above)

---

## After Downloading
1. Create folders in this repository under `packages/` matching the structure shown
2. Place downloaded files in appropriate folders
3. Run `00-master-setup-offline.sh` when ready

Done!
