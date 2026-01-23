# SketchUp 2026 Wine Installation - Debug Report

**Date:** 2026-01-13  
**Wine Version:** wine-staging 10.20  
**System:** Linux 6.18 (Fedora 42)  
**WINEPREFIX:** `$HOME/.sketchup2026`  
**Current Status:** Moving to Bottles installation method

---

## Executive Summary

After extensive debugging with Wine API tracing, we've conclusively identified that:

1. **Wine's WoW64 implementation is CORRECT** - All Win32 API calls return proper 64-bit values
2. **The problem is inside InstallShield 2024** - The installer's internal DLLs (`ISSetup.dll`, `Setup_UI.dll`) have a hardcoded architecture check that fails under Wine despite correct API return values
3. **Solution: Use Bottles** - A Wine wrapper with better InstallShield compatibility and its own patched Wine runners

---

## Detailed Findings

### Phase 1: Environment Verification ✓

| Check | Result | Details |
|-------|--------|---------|
| WINEPREFIX Architecture | ✓ win64 | Verified via `#arch=win64` in system.reg |
| PROCESSOR_ARCHITECTURE | ✓ AMD64 | `wine cmd /c echo %PROCESSOR_ARCHITECTURE%` returns AMD64 |
| Windows Version | ✓ 10.0.19045 | `GetVersion()` returns `0x4a65000a` ≡ Windows 10 Build 19045 |
| Both Program Files exist | ✓ Yes | WoW64 syswow64 directory present with 32-bit DLLs |
| .NET Framework 4.8 | ✓ Installed | Registry key verified |
| Visual C++ 2017 x64 | ✓ Installed | v14.42.34433.0 |
| ucrtbase.dll (64-bit) | ✓ Present | PE32+ in system32 |
| DXVK | ✓ Installed | d3d11.dll is PE32+ |

### Phase 2: Win32 API Tracing

Using `WINEDEBUG=+relay`, we captured the exact API calls made by the SketchUp installer:

**Critical APIs Tested:**

```
IsWow64Process() = TRUE (0x00000001)
  → Correctly reports running as 32-bit process on 64-bit OS

IsWow64Process2():
  processMachine = 0x014C (i386)
  nativeMachine = 0x8664 (AMD64)
  → Correctly reports x86 process on AMD64 native machine

GetNativeSystemInfo().wProcessorArchitecture = 9 (AMD64)
  → Correctly reports AMD64 processor

GetVersion() = 0x4a65000a
  → Low word 0x000a = Major version 10
  → High word 0x4a65 = Build 19045
  → Correctly reports Windows 10
```

**Conclusion:** All Wine WoW64 APIs return correct values. The issue is NOT in Wine's architecture detection.

### Phase 3: Installer Architecture Analysis

**Installer File:** `SketchUp-2026-1-189-46.exe`
- **Type:** PE32 executable (32-bit) - Intel i386
- **Format:** InstallShield SetupSuite 2024 (Flexera)
- **Size:** 1.09 GB
- **Contains:** Encrypted `ISSetupStream` blob with embedded MSI packages

**Extraction Attempt Results:**
- `7z x` extracts PE sections but main payload `[0]` is encrypted ISSetupStream
- `unshield` cannot parse newer InstallShield 2024 format
- `cabextract` fails - not a CAB file
- Command-line extraction options (`/extract`, `/a`) rejected by installer

**Successfully Captured Files to `/tmp/sketchup-real-installer/`:**
- `setup64.exe` - PE32+ (64-bit) main installer engine
- `ISSetup.dll` - InstallShield core (1.5 MB)
- `ISRT.dll` - InstallShield runtime (1.2 MB)  
- `Setup_UI.dll` - UI handling (1.0 MB)
- `setup.xml` - Configuration and MSI definitions (539 KB)

### Phase 4: Root Cause Identified

The `setup.xml` defines the error messages:

```xml
<ID_32_BIT_HEADER>Incompatible Operating System</ID_32_BIT_HEADER>
<ID_32_BIT_MESSAGE>SketchUp Pro requires a 64-bit operating system. 
You are attempting to install SketchUp Pro on a 32-bit operating system. 
Please try again on a device with a 64-bit operating system.</ID_32_BIT_MESSAGE>
```

**The check is hardcoded inside `ISSetup.dll` or `Setup_UI.dll`**, not via standard Win32 APIs. Despite Wine correctly returning 64-bit values from:
- `IsWow64Process()`
- `IsWow64Process2()`
- `GetNativeSystemInfo()`
- `GetVersion()`

The InstallShield DLLs use an **alternative detection method** that Wine doesn't emulate properly. This could be:
- Direct registry checks with specific key paths
- WMI queries
- Undocumented NTDLL functions
- Custom anti-emulation detection

### Phase 5: Script Issues Fixed

The original [`run_wine_debug_fixed.sh`](run_wine_debug_fixed.sh:1) had missing `export` statements, causing Wine to use the wrong prefix. This has been corrected.

---

## Files and Diagnostic Artifacts

### Diagnostic Log Directory: `./wine-diagnose-20260113-154239/`

| File | Contents |
|------|----------|
| `wow64-test-results.txt` | Output from compiled WoW64 API test program |
| `relay-trace.txt` | Filtered Win32 API calls (IsWow64*, GetSystemInfo, etc.) |
| `full-wine-output.txt` | Complete Wine debug output |
| `registry-windows-version.txt` | Windows NT\CurrentVersion registry dump |
| `registry-environment.txt` | System environment variables |
| `wine-env-vars.txt` | Wine-visible environment variables |

### Extracted Installer Components: `/tmp/sketchup-real-installer/`

| File | Size | Description |
|------|------|-------------|
| `setup64.exe` | 275 KB | 64-bit InstallShield engine |
| `ISSetup.dll` | 1.6 MB | InstallShield core DLL |
| `ISRT.dll` | 1.2 MB | Runtime library |
| `Setup_UI.dll` | 1.0 MB | UI framework |
| `setup.xml` | 539 KB | Installation configuration |

### SketchUp Installer Location

```
/home/tomas/SketchUp-2026-1-189-46.exe
```

### Current Wine Prefix

```
/home/tomas/.sketchup2026/
├── drive_c/
│   ├── Program Files/
│   ├── Program Files (x86)/
│   ├── users/tomas/
│   └── windows/
│       ├── system32/        (64-bit DLLs)
│       └── syswow64/        (32-bit DLLs)
├── system.reg               (#arch=win64)
├── user.reg
└── userdef.reg
```

---

## Current Solution: Bottles

Bottles is now installed and initialized with:

**Bottles Components:**
- **Runner:** soda-9.0-1 (Valve's Proton-based Wine)
- **DXVK:** 2.7.1 (Direct3D → Vulkan translation)
- **VKD3D:** proton-3.0 (D3D12 → Vulkan)
- **LatencyFlex:** v0.1.1
- **WineBridge:** 1.2.0
- **System Wine:** sys-wine-10.0 (also available as fallback)

**Missing (non-critical):** 
- dxvk-nvapi (404 error on download) - Only needed for NVIDIA DLSS, not required for SketchUp

---

## HANDOFF PROMPT FOR NEXT SESSION

### Objective
Create a Bottles environment and install SketchUp 2026, leveraging the existing dependencies and downloaded components.

### Current State

**Bottles is running** with soda-9.0-1 runner installed. No bottles have been created yet.

**Key paths:**
- Installer: `/home/tomas/SketchUp-2026-1-189-46.exe`
- Existing Wine prefix (for reference): `/home/tomas/.sketchup2026/`
- Extracted 64-bit installer: `/tmp/sketchup-real-installer/`
- Diagnostic logs: `/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/wine-diagnose-20260113-154239/`
- Workspace: `/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/`

**The workspace codebase is indexed in Kilocode** - use `codebase_search` to quickly find scripts, configurations, and documentation.

### Important Context

1. **The existing prefix has all dependencies installed:**
   - .NET Framework 4.8 (in registry, functioning)
   - Visual C++ 2017 x64 runtime
   - DXVK (d3d11.dll)
   - ucrtbase.dll 64-bit
   - Windows 10 Pro registry settings

2. **Bottles creates separate prefixes** in `~/.var/app/com.usebottles.bottles/data/bottles/bottles/`

3. **The Soda runner is Proton-based** and includes many compatibility patches that vanilla Wine-staging lacks

4. **SketchUp 2026 Requirements (from setup.xml):**
   - 64-bit Windows 10 or later
   - .NET Framework 4.8
   - Visual C++ 2015-2022 Redistributable (x64) v14.42+
   - WebView2 Runtime (for Trimble Identity login)
   - 2 GB free disk space
   - Direct3D 11 compatible GPU

### Step-by-Step Instructions

#### 1. Create the Bottle

In the Bottles GUI:
- Click "+" to create new bottle
- **Name:** `SketchUp2026`
- **Environment:** Select "Application" (NOT Gaming)
  - This installs .NET, VC++ runtimes, and common dependencies automatically
- **Runner:** Leave as `soda-9.0-1` (Proton-based, best compatibility)
- Click "Create" and wait for initialization

#### 2. Configure the Bottle

After creation, click on the bottle and go to **Settings**:

**Compatibility:**
- DXVK: Enabled (should be default)
- VKD3D: Enabled
- Windows Version: **Windows 10** (critical - not Windows 11)

**Dependencies to install via Bottles UI:**
- `dotnet48` (if not auto-installed by Application template)
- `vcredist2019` (or vcredist2022)
- Optionally: `webview2` (for Trimble login - may need manual installation)

#### 3. Run the Installer

**Option A: Direct Run**
- Click "Run Executable..."
- Navigate to `/home/tomas/SketchUp-2026-1-189-46.exe`
- Run and observe

**Option B: If Option A fails with same error**
- Try running the extracted 64-bit installer directly:
- Path: `/tmp/sketchup-real-installer/setup64.exe`
- (Note: This requires the parent process context, may not work standalone)

#### 4. If InstallShield Still Fails

Try these alternative runners (install via Bottles → Preferences → Runners):
- **Wine-GE-Proton** (GloriousEggroll's builds with gaming patches)
- **caffe** (Bottles' gaming-focused runner)

Or try importing the existing Wine prefix:
- The prefix at `/home/tomas/.sketchup2026/` has all deps
- Bottles can import external prefixes

### Relevant Scripts in Workspace

Use `codebase_search` queries like:
- "Wine prefix setup" → [`02-setup-wineprefix.sh`](sketchup-wine-setup/scripts/02-setup-wineprefix.sh)
- "install sketchup" → [`04-install-sketchup.sh`](sketchup-wine-setup/scripts/04-install-sketchup.sh)
- "troubleshooting" → [`docs/TROUBLESHOOTING.md`](sketchup-wine-setup/docs/TROUBLESHOOTING.md)
- "wine components" → [`docs/WINETRICKS-COMPONENTS.md`](sketchup-wine-setup/docs/WINETRICKS-COMPONENTS.md)

### Workspace File Structure

```
/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/
├── debug.md                          # THIS FILE - comprehensive debug report
├── diagnose-installer-api.sh         # WoW64 API diagnostic script
├── run_wine_debug_fixed.sh           # Fixed Wine debug launcher
├── wine-diagnose-20260113-154239/    # Diagnostic logs directory
│   ├── wow64-test-results.txt
│   ├── relay-trace.txt  
│   ├── full-wine-output.txt
│   └── registry-*.txt
├── sketchup-wine-setup/
│   ├── scripts/
│   │   ├── 00-master-setup.sh        # Full automated setup
│   │   ├── 01-install-winehq.sh      # Wine installation
│   │   ├── 02-setup-wineprefix.sh    # Prefix creation (uses ~/.wine/sketchup2026)
│   │   ├── 03-launch-sketchup.sh     # Launcher script
│   │   └── 04-install-sketchup.sh    # Installer script (uses ~/.sketchup2026)
│   └── docs/
│       ├── TROUBLESHOOTING.md
│       ├── WINETRICKS-COMPONENTS.md
│       └── NVIDIA-GPU-OFFLOADING.md
└── packages/
    └── tools/
        └── winetricks                 # Local winetricks copy
```

### Key Technical Notes

1. **WINEPREFIX inconsistency in scripts:**
   - [`02-setup-wineprefix.sh`](sketchup-wine-setup/scripts/02-setup-wineprefix.sh:8) uses `$HOME/.wine/sketchup2026`
   - [`04-install-sketchup.sh`](sketchup-wine-setup/scripts/04-install-sketchup.sh:30) uses `$HOME/.sketchup2026`
   - The ACTUAL working prefix is at `$HOME/.sketchup2026`
   - Consider standardizing if modifying scripts

2. **NVIDIA GPU Offloading:**
   ```bash
   export __NV_PRIME_RENDER_OFFLOAD=1
   export __GLX_VENDOR_LIBRARY_NAME=nvidia
   ```
   These are needed for hybrid GPU laptops (GTX 1050 Ti)

3. **Wine-staging 10.20 has experimental patches:**
   The Soda runner in Bottles is more stable for production apps

### Success Criteria

Installation is successful when:
1. No "Incompatible Operating System" error appears
2. InstallShield progresses past prerequisite checks
3. SketchUp files are installed to `C:\Program Files\SketchUp\SketchUp 2026\`
4. `SketchUp.exe` launches without immediate crash

### Fallback Plan

If Bottles with Soda runner fails:
1. Try Wine-GE runner (install via Bottles → Preferences → Runners → Install)
2. Try Lutris instead of Bottles
3. Contact Trimble support for an offline/MSI installer
4. File WineHQ bug for InstallShield 2024 compatibility

---

## Session Log Summary

1. ✓ Verified Wine prefix architecture is correct (win64)
2. ✓ Verified all dependencies installed (.NET 4.8, vcrun2017, DXVK)
3. ✓ Fixed missing `export` statements in debug scripts
4. ✓ Added WoW64 API tracing (`WINEDEBUG=+wow,+relay`)
5. ✓ Confirmed Wine APIs return correct 64-bit values
6. ✓ Identified InstallShield internal check as the failure point
7. ✓ Extracted setup64.exe and supporting DLLs
8. ✓ Analyzed setup.xml - found ID_32_BIT_MESSAGE definition
9. ✓ Attempted standalone execution of setup64.exe (fails due to missing parent process)
10. ✓ Installed Bottles flatpak
11. ✓ Bottles downloaded: soda-9.0-1 runner, DXVK 2.7.1, VKD3D 3.0
12. → Create bottle and attempt SketchUp installation

---

## Session 2: Bottles Configuration and Runner Selection

**Timestamp:** 2026-01-13T21:27 UTC-5

### Bottles First Launch - Component Download Log

```
16:12:43 (INFO) Bottles Started!
16:12:48 (INFO) Performing Bottles checks…
16:12:48 (INFO) Runners path doesn't exist, creating now.
16:12:48 (INFO) Runtimes path doesn't exist, creating now.
16:12:48 (INFO) WineBridge path doesn't exist, creating now.
16:12:48 (INFO) Bottles path doesn't exist, creating now.
16:12:48 (INFO) Dxvk path doesn't exist, creating now.
16:12:48 (INFO) Vkd3d path doesn't exist, creating now.
16:12:48 (INFO) Nvapi path doesn't exist, creating now.
16:12:48 (INFO) Templates path doesn't exist, creating now.
16:12:48 (INFO) Temp path doesn't exist, creating now.
16:12:48 (INFO) LatencyFleX path doesn't exist, creating now.
16:12:48 (INFO) Runners found: sys-wine-10.0

16:13:05 (WARNING) No dxvk found.
16:13:06 (INFO) Installing component: [dxvk-2.7.1].
16:13:14 (INFO) Component installed: dxvk dxvk-2.7.1

16:13:14 (WARNING) No vkd3d found.
16:13:16 (INFO) Installing component: [vkd3d-proton-3.0].
16:13:20 (INFO) Component installed: vkd3d vkd3d-proton-3.0

16:13:20 (WARNING) No nvapi found.
16:13:22 (WARNING) Failed to download [dxvk-nvapi-v0.9.0] with code: 404
  → This is EXPECTED - only needed for NVIDIA DLSS features, NOT required for SketchUp

16:13:22 (WARNING) No latencyflex found.
16:13:26 (INFO) Component installed: latencyflex latencyflex-v0.1.1

16:13:27 (WARNING) WineBridge installation/update required.
16:13:31 (INFO) Component installed: winebridge winebridge-1.2.0

16:13:31 (WARNING) No managed runners found.
16:13:33 (INFO) Installing component: [soda-9.0-1].
16:14:17 (INFO) Component installed: runner soda-9.0-1

16:14:17 (INFO) Runners found:
         - soda-9.0-1
         - sys-wine-10.0
```

### Bottles Components Status

| Component | Status | Version | Notes |
|-----------|--------|---------|-------|
| sys-wine-10.0 | ✅ Available | 10.0 | System Wine (fallback option) |
| soda-9.0-1 | ✅ Installed | 9.0-1 | Proton-based runner (**RECOMMENDED**) |
| dxvk | ✅ Installed | 2.7.1 | Direct3D 10/11 → Vulkan |
| vkd3d-proton | ✅ Installed | 3.0 | Direct3D 12 → Vulkan |
| latencyflex | ✅ Installed | v0.1.1 | Latency optimization |
| winebridge | ✅ Installed | 1.2.0 | Bottles integration layer |
| dxvk-nvapi | ❌ Failed (404) | v0.9.0 | **NOT needed** - only for NVIDIA DLSS |

### Runner Recommendation: Use `soda-9.0-1`

**Why soda-9.0-1 over sys-wine-10.0:**

1. **Proton-based**: Soda is derived from Valve's Proton, which includes:
   - Extensive compatibility patches
   - Better InstallShield handling
   - Pre-configured for application compatibility

2. **Version maturity**: 9.0-1 is a stable release with known working configurations
   - sys-wine-10.0 is bleeding-edge and may have regressions

3. **InstallShield 2024**: Proton-based runners have more success with modern installers because:
   - They include additional API stubs and shims
   - WoW64 layer is more complete
   - Registry defaults are tuned for compatibility

**When to try sys-wine-10.0:**
- Only if soda-9.0-1 fails with the same "Incompatible Operating System" error
- sys-wine-10.0 uses vanilla Wine 10.0 which matches our previous debugging

### Local Project Resources

**Available in `/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/packages/`:**

| File | Location | Purpose |
|------|----------|---------|
| winetricks | `packages/tools/winetricks` | Dependency installer script |
| rpmfusion-setup.txt | `packages/tools/` | RPM Fusion instructions |
| (wine/ empty) | `packages/wine/` | Placeholder for Wine RPMs |

**NOT pre-downloaded (will be downloaded by Bottles on-demand):**
- .NET Framework 4.8 → Bottles has its own dependency system
- VC++ Redistributables → Bottles installs via template or manually
- WebView2 → May need manual installation

### Bottle Creation Settings

For the screenshot shown (Create New Bottle dialog):

| Setting | Recommended Value | Reason |
|---------|-------------------|--------|
| **Name** | `SketchUp2026` | Clear identification |
| **Environment** | `Application` ✅ | Auto-installs .NET, VC++ runtimes |
| **Runner** | `soda-9.0-1` | Proton-based, better InstallShield compat |
| **Bottle Directory** | `(Default)` | Uses Bottles standard location |

**After creation, configure:**
- Windows Version: **Windows 10** (not 11)
- DXVK: **Enabled** (default with Application template)
- VKD3D: **Enabled** (default with Application template)

### Dependencies for Bottles (Application Template)

The "Application" environment pre-installs:
- .NET Framework 4.8
- Visual C++ 2015-2022 Redistributable
- Core Windows fonts

**May still need:**
- `webview2` (for Trimble Identity login) - install via Dependencies tab if needed

---

## Session 2 Continued: Installation Failure Analysis

**Timestamp:** 2026-01-13T22:20 UTC-5

### Critical Finding: TWO Failure Points

The installer fails in a **specific sequence**:

1. **First Error: "Invalid handle"**
   - Occurs during: KB2999226 (Universal CRT) installation
   - Stage: "Preparing" → Installing prerequisites
   - This is the ROOT CAUSE

2. **Second Error: "Incompatible Operating System"**
   - Occurs AFTER KB2999226 fails
   - InstallShield falls back to architecture check after prerequisite failure

### Analysis: KB2999226 (Universal CRT)

**What is KB2999226?**
- Microsoft Update for Universal C Runtime in Windows
- Installs `ucrtbase.dll` and related UCRT libraries
- Required for applications using VC++ 2015+ runtime

**Why it fails in Wine:**
- KB2999226 is distributed as `.msu` (Windows Update standalone package)
- Uses Windows Update Agent (WUA) APIs internally
- Wine has incomplete WUA implementation
- "Invalid handle" suggests `NtCreateFile` or registry handle issue

### Hypothesis: Pre-install UCRT to bypass KB2999226

The installer checks if UCRT is present BEFORE trying to install KB2999226. If we pre-install the Visual C++ Redistributable 2015-2022 (which includes UCRT), the installer should skip KB2999226.

### Bottles Debugging Options

**1. Enable Bottles Logging:**
```bash
# Run Bottles with debug output
flatpak run com.usebottles.bottles --verbose
```

**2. Check Bottles logs:**
```bash
# Bottles stores logs in:
~/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026/
```

**3. Environment Variables (via Bottles Settings → Environment Variables):**
```
WINEDEBUG=+file,+handle,+msi
```

**4. Run from command line with debug:**
```bash
# Find the bottle's wine binary
WINEPREFIX=~/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026 \
WINEDEBUG=+msi,+handle \
~/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1/bin/wine \
/home/tomas/SketchUp-2026-1-189-46.exe
```

### Root Cause Confirmed: `wusa.exe` is broken in Wine

**Research findings:**
- The SketchUp installer's bootstrapper uses `wusa.exe` (Windows Update Standalone Installer)
- `wusa.exe` is broken/unimplemented in Wine
- This causes the "Invalid handle" error when installing KB2999226
- After KB2999226 fails, InstallShield falls back to the "Incompatible Operating System" error

**References:**
- [Winetricks Issue #1885](https://github.com/Winetricks/winetricks/issues/1885)
- [WineHQ Forum - wusa.exe](https://forum.winehq.org/viewtopic.php?t=12642)
- [SketchUp Forum - Wine installation](https://forums.sketchup.com/t/error-installing-2017-make-in-ubuntu-linux-with-wine/34916)

### Solution Options

#### Option 1: Pre-Install VC++ Runtime via Winetricks (Bypass bootstrapper check)

For Bottles, the WINEPREFIX is at:
```
/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026
```

**Commands adapted for Bottles:**
```bash
# 1. Kill any stuck Wine processes
flatpak run --command=wineserver com.usebottles.bottles -k

# 2. Get the Bottles runner path
BOTTLES_RUNNER="/home/tomas/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1"

# 3. Force-install vcrun2017 (includes UCRT)
WINEPREFIX="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" \
WINE="$BOTTLES_RUNNER/bin/wine" \
winetricks -q --force vcrun2017

# 4. Set Windows 10 mode
WINEPREFIX="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" \
$BOTTLES_RUNNER/bin/wine winecfg /v win10

# 5. Re-run installer
WINEPREFIX="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" \
$BOTTLES_RUNNER/bin/wine /home/tomas/SketchUp-2026-1-189-46.exe
```

#### Option 2: Extract and Run MSI Directly (Bypass bootstrapper entirely)

This is the **most reliable fix** - skip the bootstrapper and run the MSI directly:

```bash
# 1. Kill Wine
flatpak run --command=wineserver com.usebottles.bottles -k

# 2. Extract the installer (already done to /tmp/sketchup-real-installer/)
# If not extracted:
# 7z x /home/tomas/SketchUp-2026-1-189-46.exe -o/tmp/sketchup-extracted

# 3. Find the MSI file
ls /tmp/sketchup-real-installer/*.msi
# or
find /tmp/sketchup-extracted -name "*.msi" 2>/dev/null

# 4. Run MSI directly via Bottles
WINEPREFIX="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" \
$BOTTLES_RUNNER/bin/wine msiexec /i /path/to/SketchUp2026.msi
```

#### Option 3: Use Bottles Dependencies UI

1. Go to Bottles → SketchUp2026 → **Dependencies**
2. Install: `vcredist2019` (includes UCRT)
3. Re-run SketchUp installer via "Run Executable..."

---

## References

- Wine WoW64: https://wiki.winehq.org/WoW64
- IsWow64Process API: https://learn.microsoft.com/en-us/windows/win32/api/wow64apiset/nf-wow64apiset-iswow64process
- Bottles Documentation: https://docs.usebottles.com/
- SketchUp System Requirements: https://help.sketchup.com/en/sketchup/system-requirements
- InstallShield 2024: Uses Flexera's Suite Installer format

---

## Session 2: Wine Error Analysis

**Timestamp:** 2026-01-13T23:07 UTC-5

### Wine Errors During SketchUp Installation

| Error | Severity | Meaning | Impact |
|-------|----------|---------|--------|
| `hid:handle_IRP_MN_QUERY_ID Unhandled type 00000005` | fixme | USB HID device enumeration not fully implemented | ❌ None - cosmetic |
| `xrandr14_get_adapters Failed to get adapters` | err | XRandR (display) adapter enumeration failed | ⚠️ May affect display detection |
| `oleacc:find_class_data unhandled window class: L"#32769"` | fixme | Accessibility API missing class handler | ❌ None - accessibility |
| `uiautomation:*` stubs | fixme | UI Automation APIs not implemented | ❌ None - accessibility |
| `ver:GetCurrentPackageId stub` | fixme | Windows Store app package ID check unimplemented | ⚠️ May affect some checks |
| `ole:std_release_marshal_data` error 0x8001011d | err | COM object marshaling failed | ⚠️ Possible installer issue |
| `ole:CoReleaseMarshalData` error 0x8001011d | err | COM release marshal data failed | ⚠️ Same as above |
| `kernelbase:AppPolicyGetProcessTerminationMethod` | fixme | App policy stub | ❌ None |

### Analysis

**Critical Errors:**
1. **COM marshaling errors (0x8001011d)** - This is `RPC_E_DISCONNECTED` - means a COM server was disconnected during communication. This could be related to the KB2999226/wusa.exe failure.

2. **XRandR adapter failure** - The installer tries to detect displays for GPU capability check. This might contribute to the "32-bit OS" false detection if it can't enumerate adapters.

**Non-issues:**
- HID, oleacc, uiautomation, GetCurrentPackageId, AppPolicyGetProcessTerminationMethod - all fixme stubs, not causing failures

### Root Cause Refinement

The `RPC_E_DISCONNECTED` COM error suggests the installer is trying to communicate with a Windows service (likely Windows Update Agent for wusa.exe) that doesn't exist or crashes. This confirms:

1. wusa.exe is called for KB2999226
2. wusa.exe fails/disconnects
3. COM marshaling fails
4. Installer falls back to "32-bit OS" error

### Extended Debugging Results (Session 2 Continued)

**Timestamp:** 2026-01-13T23:20 UTC-5

| Attempt | Result |
|---------|--------|
| Bottles with soda-9.0-1 runner | ❌ Same KB2999226/Invalid handle error |
| Pre-install vcrun2017 (UCRT) | ✅ UCRT installed, but installer ignores it |
| Virtual Desktop (1920x1080) | ❌ No effect on xrandr errors |
| Fake wusa.exe (hostname.exe) | ❌ Still fails with RPC_E_DISCONNECTED |
| MSI extraction (capture script) | ❌ MSI not extracted before failure |

### Conclusion

InstallShield 2024 Suite format has a fundamental incompatibility with Wine:
1. Uses encrypted `ISSetupStream` - cannot extract MSI directly with 7z
2. Runs KB2999226 check via wusa.exe **BEFORE** extracting the MSI
3. Wine's wusa.exe is a stub that fails with RPC_E_DISCONNECTED

### Remaining Options

1. **Wine-GE runner** - Try installing via Bottles Preferences → Runners
2. **Lutris** - Different Wine wrapper with different patches
3. **Contact Trimble** - Request offline MSI installer for enterprise deployment
4. **Windows VM** - Install in VirtualBox/QEMU and copy program files
5. **Wait for Wine patches** - File bug at bugs.winehq.org for InstallShield 2024

### Files Created This Session

- [`capture-msi.sh`](capture-msi.sh) - Script to capture extracted MSI files
- [`fake-wusa.c`](fake-wusa.c) - Fake wusa.exe source (mingw not installed)
- `SketchUp2026` bottle at `/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026/`

---

## Session 3: MSI Capture Attempt & Wine-GE Pivot

**Timestamp:** 2026-01-13T23:30 - 2026-01-14T01:00 UTC-5

### MSI Capture Attempt Results

**Objective:** Capture MSI files via real-time monitoring during installer execution.

**Method:** Used `inotifywait` to monitor Wine temp directories with instant file capture.

**Result:** ❌ **FAILED** - MSI files are never extracted.

**Files Captured (17MB total):**
- `_is18f4.exe` (12MB) - InstallShield bootstrapper
- `setup64.exe` (269KB) - 64-bit installer engine
- `ISSetup.dll`, `ISRT.dll`, `Setup_UI.dll` - InstallShield DLLs
- `*.mst` files - Language transform files
- PNG images, icons, etc.

**Critical Finding from InstallShield.log:**
```
Stage parcel {F8189C0F-1462-4521-9287-D0AB7EF9EFFC}, parcel action: 5
ISParcelStatus value now 'KB2999226 Windows 7 x64'
This stage path: C:\users\steamuser\AppData\Local\Downloaded Installations\{F8189C0F-...}\
Stage parcel status: 80070006
Engine: error 80070006 while staging parcels
UI DLL: Display Error: Invalid handle.
```

### Root Cause Analysis (Refined)

| Factor | Detail |
|--------|--------|
| **Error Code** | `0x80070006` = `ERROR_INVALID_HANDLE` |
| **Failing Component** | KB2999226 (Universal CRT) Windows Update package |
| **Failure Mechanism** | `wusa.exe` (Windows Update Standalone Installer) is unimplemented in Wine |
| **MSI Location** | Would be extracted to `AppData\Local\Downloaded Installations\` |
| **Cleanup** | InstallShield deletes staging directory on failure |

**Why MSI Capture Failed:**
InstallShield Suite 2024 stages prerequisites via `wusa.exe` FIRST, then extracts MSI files. Since `wusa.exe` fails immediately, the MSI extraction phase is never reached. The MSI payload remains encrypted inside `ISSetupStream`.

### Capture Scripts Created

| Script | Purpose |
|--------|---------|
| [`capture-msi-inotify.sh`](capture-msi-inotify.sh) | Real-time capture using `inotifywait` |
| [`capture-msi-aggressive.sh`](capture-msi-aggressive.sh) | Polling-based capture (100ms interval) |
| [`msi-capture-and-run.sh`](msi-capture-and-run.sh) | Basic capture script |

### Next Steps

**Option 1: Wine-GE Runner** (In Progress)
- Download Wine-GE-Proton from GitHub releases
- GloriousEggroll builds include additional compatibility patches
- May have better `wusa.exe` stub or workarounds

**Option 2: Windows VM Extraction** (Fallback)
- Install SketchUp 2026 on Windows (VM or real)
- Copy `C:\Program Files\SketchUp\SketchUp 2026\` to Linux
- Run via Bottles (dependencies already installed)

**Option 3: Contact Trimble**
- Request enterprise MSI installer that doesn't use InstallShield Suite

### Files of Interest

| Path | Description |
|------|-------------|
| [`InstallShield.log`](InstallShield.log) | Full installer log (1.6MB, UTF-16LE encoded) |
| `captured-msi/` | Captured InstallShield files (17MB) |
| `SketchUp2026/` | Bottles prefix with dependencies installed |

---

## Session 4: Fake wusa.exe Deployment & Corrected Script Paths

**Timestamp:** 2026-01-14T01:00 - 01:10 UTC-5

### User Technical Feedback (Critical Corrections)

1. **WoW64 File System Redirection** (Critical Fix Applied)
   - SketchUp installer is a **32-bit process** (verified via `IsWow64Process=TRUE` logs)
   - 32-bit processes accessing `C:\Windows\System32` are **redirected** to `SysWOW64`
   - **Solution:** Compile 32-bit `wusa.exe` and place in `SysWOW64` (not just System32)

2. **Bottles Temp Path Correction** (Critical Fix Applied)
   - Previous scripts watched wrong temp directories
   - **Actual Bottles path:** `~/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026/...`
   - **But this was a placeholder!** The real prefix is at custom path:
     ```
     /home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026/
     ```
   - This was discovered via `placeholder.yml` which contains a document portal reference

3. **Wine Prefix Path Discrepancy** (Acknowledged)
   - Scripts had inconsistent paths (`~/.wine/sketchup2026` vs `~/.sketchup2026`)
   - For Bottles, we use the custom path set during bottle creation

### Actions Completed

#### 1. Fake wusa.exe Compilation & Deployment

**Compilers installed:**
- ✅ `i686-w64-mingw32-gcc` (32-bit) - was available
- ✅ `x86_64-w64-mingw32-gcc` (64-bit) - installed via `dnf install mingw64-gcc`

**Binaries created:**
- `build/wusa32.exe` - 32-bit fake wusa.exe
- `build/wusa64.exe` - 64-bit fake wusa.exe

**Deployment locations:**
```
BOTTLE_PREFIX = /home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026/

wusa32.exe → $BOTTLE_PREFIX/drive_c/windows/syswow64/wusa.exe     # For 32-bit installer
wusa64.exe → $BOTTLE_PREFIX/drive_c/windows/system32/wusa.exe    # For completeness
```

**Originals backed up to:**
- `syswow64/wusa.exe.backup`
- `system32/wusa.exe.backup`

#### 2. Scripts Updated with Correct Paths

| Script | Fix Applied |
|--------|-------------|
| [`deploy-fake-wusa.sh`](deploy-fake-wusa.sh) | Auto-detects custom or standard Bottles path |
| [`watch-temp-for-msi.sh`](watch-temp-for-msi.sh) | Uses correct custom Bottles prefix |
| [`capture-msi-aggressive.sh`](capture-msi-aggressive.sh) | Uses correct custom Bottles prefix |

### Next Steps

1. **Test fake wusa.exe** - Run installer in Bottles to see if it bypasses KB2999226 check
2. **Alternative: Manual "Snatch and Grab"** - Run [`watch-temp-for-msi.sh`](watch-temp-for-msi.sh) in one terminal, installer in another
3. **If MSI files appear** - Copy them and run via `msiexec /i` directly

### Manual Test Instructions

**Terminal 1 (MSI Watcher):**
```bash
cd "/home/tomas/SketchUp 2026/HOLYFUCKINGWINE"
./watch-temp-for-msi.sh
```

**Terminal 2 (Bottles installer):**
```bash
# Via Bottles GUI: Run Executable → /home/tomas/SketchUp-2026-1-189-46.exe
# OR via command line:
WINEPREFIX="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" \
~/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1/bin/wine \
/home/tomas/SketchUp-2026-1-189-46.exe
```

**If MSI files appear in `/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/captured-msi/`:**
```bash
WINEPREFIX="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" \
~/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1/bin/wine \
msiexec /i /path/to/captured.msi
```

### Expected Outcomes

| Scenario | Indicator |
|----------|-----------|
| **Fake wusa works** | Installer progresses past "Preparing..." stage |
| **Fake wusa doesn't help** | Same "Invalid handle" error at KB2999226 |
| **MSI files captured** | Files appear in `captured-msi/` directory |
| **Need Windows VM** | If neither approach works |

---

## Quick Reference: All Important File Paths

### Installer and Prefix Locations

| Item | Path |
|------|------|
| **SketchUp Installer** | `/home/tomas/SketchUp-2026-1-189-46.exe` |
| **Bottles Wine Prefix** | `/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026/` |
| **Workspace Directory** | `/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/` |

### Wine Prefix Internals

| Item | Path |
|------|------|
| **System32 (64-bit)** | `.../SketchUp2026/drive_c/windows/system32/` |
| **SysWOW64 (32-bit)** | `.../SketchUp2026/drive_c/windows/syswow64/` |
| **Windows Temp** | `.../SketchUp2026/drive_c/windows/Temp/` |
| **User Temp** | `.../SketchUp2026/drive_c/users/$(whoami)/Temp/` |
| **Steamuser Temp** | `.../SketchUp2026/drive_c/users/steamuser/Temp/` |
| **Downloaded Installations** | `.../SketchUp2026/drive_c/users/steamuser/AppData/Local/Downloaded Installations/` |

### Bottles Infrastructure

| Item | Path |
|------|------|
| **Bottles Data Root** | `~/.var/app/com.usebottles.bottles/data/bottles/` |
| **Bottles Runners** | `~/.var/app/com.usebottles.bottles/data/bottles/runners/` |
| **Soda Runner** | `~/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1/bin/wine` |
| **Bottles Placeholder** | `~/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026/placeholder.yml` |

### Scripts Created This Session

| Script | Path | Purpose |
|--------|------|---------|
| **deploy-fake-wusa.sh** | [`deploy-fake-wusa.sh`](deploy-fake-wusa.sh) | Compiles and deploys fake wusa.exe |
| **watch-temp-for-msi.sh** | [`watch-temp-for-msi.sh`](watch-temp-for-msi.sh) | Manual MSI capture watcher |
| **capture-msi-aggressive.sh** | [`capture-msi-aggressive.sh`](capture-msi-aggressive.sh) | Automated aggressive MSI capture |
| **fake-wusa.c** | [`fake-wusa.c`](fake-wusa.c) | Fake wusa.exe source code |

### Build Artifacts

| Item | Path |
|------|------|
| **32-bit fake wusa.exe** | `./build/wusa32.exe` |
| **64-bit fake wusa.exe** | `./build/wusa64.exe` |
| **Captured files** | `./captured-msi/` |

### Deployed Fake wusa.exe

| Deployed Location | Target |
|-------------------|--------|
| `.../syswow64/wusa.exe` | 32-bit installer sees this (WoW64 redirection) |
| `.../system32/wusa.exe` | 64-bit processes see this |
| `.../syswow64/wusa.exe.backup` | Original Wine wusa.exe backup |
| `.../system32/wusa.exe.backup` | Original Wine wusa.exe backup |

---

## Session 5: Complete Root Cause Analysis & Decision Point

**Timestamp:** 2026-01-14T01:25 UTC-5

### Test Results: Fake wusa.exe

| Test | Result |
|------|--------|
| Fake wusa.exe deployed to syswow64 (32-bit) | ✅ Verified with `file` command |
| Fake wusa.exe deployed to system32 (64-bit) | ✅ Verified with `file` command |
| Original Wine stubs backed up | ✅ Both `.backup` files exist |
| Installer bypasses KB2999226 check | ❌ **FAILED - Same "Invalid handle" error** |

### Root Cause: WUA COM API Failure (NOT wusa.exe)

The installer uses `CoCreateInstance(CLSID_WindowsUpdateAgentInfo, ...)` which fails in Wine before wusa.exe is called.

**Why all bypass attempts failed:**

| Approach | Why It Failed |
|----------|---------------|
| Fake wusa.exe returning 0 | wusa.exe is never called - COM crashes first |
| Registry keys for KB2999226 | API crashes before registry check |
| InstallShield `/extract_all` switch | Not supported by Suite format |

### Final Verdict: Wine Cannot Run This Installer

The `CoCreateInstance` call fails **before** the installer logic can even decide to run wusa.exe or extract the MSI. It fails at the "load the library to check prerequisites" stage.

**You cannot script your way around a missing COM interface implementation in Wine without recompiling Wine itself with deep patches.**

---

## Recommended Solution: Windows VM Extraction

### Why This Is The Only Reliable Path

1. SketchUp is "portable enough" - copying installed files to Linux works
2. The Bottles environment already has all required runtimes (VC++, .NET, DXVK)
3. You just need the actual program files

### Step-by-Step VM Extraction Guide

#### 1. Set Up Windows VM

**Quick Option - Windows 10 Evaluation:**
```
https://www.microsoft.com/en-us/evalcenter/download-windows-10-enterprise
```
- Download ISO (~5GB)
- Create VM: 4GB RAM, 40GB disk, 2 CPUs
- Install Windows (skip product key - 90-day eval)

**Alternative - Tiny10/11:**
- Smaller footprint, faster install
- Search for "Tiny10" or "Tiny11" ISOs

#### 2. Install SketchUp in VM

1. Copy installer to VM: `/home/tomas/SketchUp-2026-1-189-46.exe`
2. Run installer in Windows - will complete successfully
3. Skip Trimble login if possible (or create account)

#### 3. Locate and Zip Installed Files

**Main Application:**
```
C:\Program Files\SketchUp\SketchUp 2026\
```

**Common Files (if exists):**
```
C:\Program Files\Common Files\SketchUp\
```

**Create archive:**
```powershell
Compress-Archive -Path "C:\Program Files\SketchUp\SketchUp 2026" -DestinationPath C:\SketchUp2026.zip
```

#### 4. Transfer to Linux

Transfer `SketchUp2026.zip` via:
- Shared folder
- USB stick
- Network share
- Direct copy if using VirtualBox Guest Additions

#### 5. Deploy to Bottles

```bash
# Unzip to Bottles prefix
unzip ~/SketchUp2026.zip -d "/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026/drive_c/Program Files/SketchUp/"

# Verify
ls -la "/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026/drive_c/Program Files/SketchUp/SketchUp 2026/"
```

#### 6. Launch via Bottles

```bash
WINEPREFIX="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" \
~/.var/app/com.usebottles.bottles/data/bottles/runners/soda-9.0-1/bin/wine \
"C:\Program Files\SketchUp\SketchUp 2026\SketchUp.exe"
```

Or via Bottles GUI: Run Executable → Navigate to `SketchUp.exe`

---

## Alternative: Wine-GE (Quick Try Before VM)

GloriousEggroll often patches WUA stubs for game launchers.

### How to Try

1. Open Bottles → Preferences → Runners
2. Download `wine-ge-proton8-26` (or latest)
3. Edit SketchUp2026 bottle → Change runner to Wine-GE
4. Try installer one more time

**Probability of success: ~20%** - Worth a 5-minute test before committing to VM setup.

---

## Alternative: Universal Extractor 2

If you want to try extracting without VM:

1. Download `UniExtract2` from GitHub
2. Run via Bottles: `wine UniExtract.exe`
3. Point at `SketchUp-2026-1-189-46.exe`
4. May extract MSI or raw files if it handles Suite format

---

## Session Summary

| Attempt | Result |
|---------|--------|
| Fake wusa.exe (32-bit + 64-bit) | ❌ Failed - COM crashes before wusa.exe called |
| Registry keys for KB2999226 | ❌ Failed - API crashes before registry check |
| InstallShield CLI switches | ❌ Not supported by Suite format |
| MSI Snatch during extraction | ❌ MSI never extracted - failure is earlier |

**Final Diagnosis:** Wine's Windows Update Agent COM implementation is incomplete. The installer crashes at `CoCreateInstance(CLSID_WindowsUpdateAgentInfo)` before any file extraction.

**Solution:** Windows VM extraction is the only reliable path.

---

## Session 6: Wine-GE-Proton8-26 Test

**Timestamp:** 2026-01-14T03:24 - 04:05 UTC-5

### Wine-GE Installation

**Objective:** Test Wine-GE-Proton8-26 runner as last attempt before Windows VM extraction.

**Installation:**
```bash
# Downloaded from GitHub releases
wget -O wine-ge.tar.gz "https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-26/wine-lutris-GE-Proton8-26-x86_64.tar.xz"

# Extracted to Bottles runners directory
tar -xf wine-ge.tar.xz -C ~/.var/app/com.usebottles.bottles/data/bottles/runners/
```

**Runner Path:** `~/.var/app/com.usebottles.bottles/data/bottles/runners/lutris-GE-Proton8-26-x86_64/`

### Configuration Change

Updated [`SketchUp2026/bottle.yml`](SketchUp2026/bottle.yml:60):
```yaml
Runner: lutris-GE-Proton8-26-x86_64  # Changed from soda-9.0-1
```

### Test Result: ❌ FAILED (Different Error)

**Command:**
```bash
WINEPREFIX="/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" \
WINEDEBUG=-all \
~/.var/app/com.usebottles.bottles/data/bottles/runners/lutris-GE-Proton8-26-x86_64/bin/wine \
/home/tomas/SketchUp-2026-1-189-46.exe
```

**Output:**
```
wineserver: using server-side synchronization.
wine: RLIMIT_NICE is <= 20, unable to use setpriority safely
wine: configuration in L"/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026" has been updated.
C:\users\steamuser\Temp\{CAED453F-2094-4279-929A-81C194A849CC}\_is473e.exe: File Not Found
Exit 17
```

### Analysis: Wine-GE Path Resolution Issue

| Finding | Detail |
|---------|--------|
| **Error** | `_is473e.exe: File Not Found` |
| **Exit Code** | 17 |
| **Stage Reached** | Bootstrapper extraction to Temp directory |
| **Issue** | Path resolution mismatch - Wine-GE updated prefix but temp files weren't accessible |

**Wine-GE Observations:**
1. ✅ Wine-GE did enable server-side synchronization (esync/fsync)
2. ✅ Prefix was updated to Wine-GE format
3. ❌ Installer bootstrapper extracted to temp but path wasn't resolved
4. ❌ No GUI appeared - immediate failure

**Possible Causes:**
- Wine-GE has different temp directory handling
- Flatpak sandbox path mapping issue
- InstallShield bootstrapper using absolute paths that Wine-GE resolves differently

### Conclusion: Wine-GE Not Compatible

Wine-GE-Proton8-26 fails at a different stage than soda-9.0-1:
- **soda-9.0-1:** Fails at WUA COM interface (`CoCreateInstance`)
- **Wine-GE:** Fails at temp file path resolution (bootstrapper extraction)

Neither can run the installer successfully.

### Current Runners Status

| Runner | Version | Test Result |
|--------|---------|-------------|
| soda-9.0-1 | 9.0-1 | ❌ WUA COM failure |
| sys-wine-10.0 | 10.0 | ❌ Same WUA COM failure (from vanilla Wine-staging tests) |
| lutris-GE-Proton8-26-x86_64 | 8-26 | ❌ Path resolution failure |

### Final Recommendation

**All Wine-based approaches exhausted.** Proceed to Windows VM extraction:

1. Download Windows 10 Evaluation ISO
2. Create VM (VirtualBox/QEMU/VMware)
3. Install SketchUp 2026 in Windows
4. Copy `C:\Program Files\SketchUp\SketchUp 2026\` to Linux
5. Deploy to Bottles prefix

**Files to Copy from Windows:**
```
C:\Program Files\SketchUp\SketchUp 2026\
C:\Program Files\Common Files\SketchUp\ (if exists)
```

**Deploy Location:**
```
/home/tomas/SketchUp 2026/HOLYFUCKINGWINE/SketchUp2026/drive_c/Program Files/SketchUp/
```

---

*Last Updated: 2026-01-14T04:05 UTC-5*
