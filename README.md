# LenovoLegionLinux Kernel 7.0 Fix (CachyOS)

> ⚠️ **This is a temporary patch for ONE specific device only!**
> 
> - Laptop: **Lenovo Legion 5 15ACH6H** (Model 82JU)
> - BIOS: **GKCN65WW**
> - Will NOT work on other Legion models - different BIOS/ACPI IDs
> - For other devices: Wait for original maintainer (johnfanv2) to add Kernel 7.0 support

## Quick Install

```bash
tar -xzf LenovoLegionLinux-kernel7-fix.tar.gz
cd LenovoLegionLinux-kernel7-fix
sudo ./install.sh
```

## What This Fixes

| Issue | Fix |
|-------|-----|
| Driver won't load on Kernel 7.0 | Changed ACPI device ID (PNP0C09 → VPC2004) |
| Rapid charging not working | Added QCHO ACPI method fallback |
| Build fails on CachyOS | Auto-detect Clang toolchain |

## Tested Features

- ✅ Rapid Charging
- ✅ Battery Conservation (Fn+R)
- ✅ Touchpad Toggle (Fn+Q)
- ✅ Fan Speed / Temperature
- ✅ Power Modes
- ✅ Platform Profile
- ✅ Fan Curve
- ✅ Keyboard LED
- ✅ Y-Logo LED

## Kernel Updates

When kernel updates (e.g., 7.0.0 → 7.0.1), rebuild manually:

```bash
sudo pacman -S clang make linux-headers
cd /path/to/LenovoLegionLinux-kernel7-fix
make -C kernel_module KVERSION=$(uname -r) CC=clang modules
sudo cp kernel_module/legion_laptop.ko /lib/modules/$(uname -r)/kernel/drivers/platform/x86/
sudo depmod -a
sudo modprobe -r legion_laptop
sudo modprobe legion_laptop force=1
```

## Uninstall

```bash
sudo ./uninstall.sh
```

## Credits

- Original driver: [johnfanv2/LenovoLegionLinux](https://github.com/johnfanv2/LenovoLegionLinux)
- Patch by: v4cachy
