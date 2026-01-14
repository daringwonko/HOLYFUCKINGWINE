# Quick Reference Guide

## 🚀 Fastest Way to Get Started

```bash
cd sketchup-wine-setup
chmod +x scripts/*.sh
./scripts/00-master-setup.sh  # ~20-30 minutes first time
./scripts/04-install-sketchup.sh
./scripts/03-launch-sketchup.sh
```

## ✅ Verify Everything Works

```bash
./scripts/verify-setup.sh
```

## 📋 All Scripts

| Script | Purpose | Runtime |
|--------|---------|---------|
| `00-master-setup.sh` | Install Wine + everything | 20-30 min |
| `04-install-sketchup.sh` | Install SketchUp | 5-15 min |
| `03-launch-sketchup.sh` | Run SketchUp | 30s-1m |
| `verify-setup.sh` | Check status | <1 min |

## 🎯 For Different Situations

### First Time Setup
```bash
./scripts/00-master-setup.sh
./scripts/04-install-sketchup.sh
./scripts/03-launch-sketchup.sh
```

### Just Launch SketchUp
```bash
./scripts/03-launch-sketchup.sh
```

### Check What's Installed
```bash
./scripts/verify-setup.sh
```

### Reinstall Everything Fresh
```bash
rm -rf ~/.sketchup2026
./scripts/00-master-setup.sh
./scripts/04-install-sketchup.sh
```

## 🔧 Manual Commands

### Check Wine
```bash
wine --version
```

### Explore Wine Prefix
```bash
ls ~/.sketchup2026/drive_c/
```

### View SketchUp Installation
```bash
ls ~/.sketchup2026/drive_c/Program\ Files/SketchUp/
```

### Check NVIDIA GPU
```bash
nvidia-smi
```

### Force GPU Usage (Manual)
```bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
wine ~/path/to/SketchUp.exe
```

## 📊 Key Paths

| Item | Path |
|------|------|
| Wine Prefix | `~/.sketchup2026` |
| SketchUp | `~/.sketchup2026/drive_c/Program Files/SketchUp/SketchUp 2026/` |
| Config | `sketchup-wine-setup/config/` |
| Docs | `sketchup-wine-setup/docs/` |
| Scripts | `sketchup-wine-setup/scripts/` |

## 🆘 Quick Troubleshooting

**Wine not found**
```bash
./scripts/00-master-setup.sh
```

**SketchUp won't launch**
```bash
./scripts/verify-setup.sh
```

**GPU not being used**
- Check: `nvidia-smi`
- Scripts automatically set GPU variables
- See: `docs/NVIDIA-GPU-OFFLOADING.md`

**Login screen won't appear**
- Wait 1-2 minutes (WebView2 downloading)
- See: `docs/TROUBLESHOOTING.md`

## 📚 Documentation

- **README.md** - Full setup guide
- **NVIDIA-GPU-OFFLOADING.md** - GPU details
- **TROUBLESHOOTING.md** - Problem solving
- **WINETRICKS-COMPONENTS.md** - Technical info

## 💾 Important Files

### Scripts (must be executable)
```bash
chmod +x sketchup-wine-setup/scripts/*.sh
```

### Do NOT modify
- `config/system.reg` - Unless you know what you're doing

### Backup these if needed
- `~/.sketchup2026` - Your entire Wine prefix
- `~/.sketchup2026/drive_c/users/` - SketchUp user data

---

**For complete documentation:** See `sketchup-wine-setup/README.md`
