# UniExtract2: Alternative Extraction Method

## What is UniExtract2?

**Universal Extractor 2 (UniExtract2)** is an open-source tool designed to extract files from virtually any type of archive or installer package. It's the successor to the original Universal Extractor and supports over 100 archive formats.

**GitHub:** https://github.com/Bioruebe/UniExtract2

## Why It Might Help

Your SketchUp installer uses **InstallShield 2024 Suite** format with an encrypted `ISSetupStream` blob. Standard tools fail:

| Tool | Result |
|------|--------|
| 7-Zip | Cannot extract ISSetupStream (encrypted/proprietary) |
| unshield | Only works with older InstallShield CAB formats |
| innounp | Wrong format (Inno Setup only) |
| lessmsi | Wrong format (MSI only) |

UniExtract2 includes **multiple extraction backends** and can often crack formats that individual tools cannot:

- InstallShield (multiple versions)
- Wise Installer
- NSIS
- Inno Setup
- Self-extracting archives
- And many more

## How UniExtract2 Works

UniExtract2 uses a cascade approach:
1. Identifies installer type via signature analysis
2. Tries primary extractor for that type
3. Falls back to alternative extractors
4. Uses brute-force binary extraction as last resort

For InstallShield Suite, it may use:
- `isxunpack` (InstallShield X unpacker)
- `iscab` (InstallShield CAB extractor)
- Direct `ISSetupStream` decryption (if keys are known)
- Binary scan for embedded PE files

## Installation (Run via Wine)

UniExtract2 is a Windows application, so you'll run it in Wine:

### Option 1: Portable Version (Recommended)

```bash
# Download latest release
cd ~/Downloads
wget https://github.com/Bioruebe/UniExtract2/releases/download/v2.0.0-rc.4/UniExtractRC4.zip

# Extract
unzip UniExtractRC4.zip -d ~/uniextract2

# Run via Wine (use your existing Bottles prefix)
export WINEPREFIX="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026"
wine ~/uniextract2/UniExtract.exe
```

### Option 2: Via Bottles

1. Download `UniExtractRC4.zip` from GitHub releases
2. Extract on Linux
3. In Bottles, use "Run Executable" and select `UniExtract.exe`

## Usage

### GUI Method

1. Launch UniExtract2
2. Drag and drop `SketchUp-2026-x-xxx-xx.exe` onto the window
3. Select output directory
4. Click "OK" and wait

### Command Line Method

```bash
export WINEPREFIX="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/SketchUp2026"

# Basic extraction
wine ~/uniextract2/UniExtract.exe "Z:\home\tomas\SketchUp-2026-1-189-46.exe" "Z:\home\tomas\sketchup-extracted"

# With scan mode (more thorough)
wine ~/uniextract2/UniExtract.exe /scan "Z:\home\tomas\SketchUp-2026-1-189-46.exe"
```

## What To Look For

If extraction succeeds, you should find:

```
sketchup-extracted/
├── SketchUp.exe           # Main executable
├── SketchUp.dll           # Core library
├── *.msi                  # MSI packages (can be installed separately)
├── ISSetup.dll            # InstallShield runtime (not needed)
├── setup.exe              # Inner setup (not needed)
└── [various files]
```

**Key files to look for:**
- `*.msi` - These can be installed directly with `wine msiexec /i file.msi`
- `SketchUp.exe` - Main application
- Any `cab` or `data` files - May contain the actual program

## Success Probability: ~40%

This approach has moderate success because:

**Pros:**
- UniExtract2 handles many InstallShield variants
- Doesn't need to "run" the installer, just extract
- Can sometimes bypass installer DRM/checks

**Cons:**
- InstallShield 2024 is relatively new, may not be fully supported
- `ISSetupStream` encryption may block extraction
- May extract installer components but not actual program files

## If UniExtract2 Fails

Check the log output for clues:
```bash
cat ~/uniextract2/log/*.log
```

Common failure modes:
- "Unknown archive format" → ISSetupStream encryption not supported
- "No files extracted" → Format recognized but encrypted
- Partial extraction → Some files may still be usable

## Alternative: 7-Zip with InstallShield Plugin

Some users report success with 7-Zip's experimental InstallShield support:

```bash
# Install p7zip
sudo dnf install p7zip p7zip-plugins

# Try extraction
7z x SketchUp-2026-1-189-46.exe -osketchup-extracted

# If that fails, try listing contents
7z l SketchUp-2026-1-189-46.exe
```

## Summary

UniExtract2 is worth trying because:
1. It's non-destructive (just extraction, no execution)
2. Supports multiple extraction backends
3. May bypass the installer's runtime checks entirely
4. Free and open source

If it extracts an MSI file, you're golden - MSI files can be installed directly with `wine msiexec` without any of the InstallShield complications.

---

*Document created: 2026-01-23*
*Part of HOLYFUCKINGWINE debugging toolkit*
