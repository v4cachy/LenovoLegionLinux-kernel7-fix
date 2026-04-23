#!/bin/bash
# LenovoLegionLinux Kernel 7.0 Fix Uninstaller
# Restores original module

set -e

KERNEL_VERSION=$(uname -r)
MODULE_PATH="/lib/modules/${KERNEL_VERSION}/kernel/drivers/platform/x86/legion-laptop.ko"

echo "=========================================="
echo "LenovoLegionLinux Kernel 7.0 Fix Uninstaller"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Unload module
if lsmod | grep -q "legion_laptop"; then
    echo "Unloading legion_laptop..."
    modprobe -r legion_laptop
fi

# Remove installed module
if [ -f "$MODULE_PATH" ]; then
    echo "Removing module..."
    rm -f "$MODULE_PATH"
fi

# Reload original ideapad_laptop if needed
echo "Reloading ideapad_laptop..."
modprobe ideapad_laptop 2>/dev/null || true

echo ""
echo "=========================================="
echo "✅ Uninstallation complete"
echo "=========================================="
echo ""
echo "To reinstall original driver, rebuild from source:"
echo "  cd ~/LenovoLegionLinux"
echo "  git checkout kernel_module/Makefile kernel_module/legion-laptop.c"
echo "  make"
echo "  sudo make install"
