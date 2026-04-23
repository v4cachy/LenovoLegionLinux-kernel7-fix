#!/bin/bash
# LenovoLegionLinux Kernel 7.0 Fix Installer
# Fixed by: v4cachy

set -e

KERNEL_VERSION=$(uname -r)
MODULE_PATH="/lib/modules/${KERNEL_VERSION}/kernel/drivers/platform/x86/legion-laptop.ko"

echo "=========================================="
echo "LenovoLegionLinux Kernel 7.0 Fix Installer"
echo "Fixed by: v4cachy"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Check if module file exists
if [ ! -f "$(dirname "$0")/legion-laptop-kernel7.ko" ]; then
    echo "ERROR: legion-laptop-kernel7.ko not found!"
    echo "Please run this script from the extracted directory."
    exit 1
fi

# Stop existing services
echo "Stopping existing services..."
systemctl stop legiond 2>/dev/null || true

# Unload existing modules
echo "Unloading existing modules..."
rmmod legion_laptop 2>/dev/null || true
rmmod ideapad_laptop 2>/dev/null || true

# Install module
echo "Installing patched module for kernel: $KERNEL_VERSION"
cp "$(dirname "$0")/legion-laptop-kernel7.ko" "$MODULE_PATH"

# Load dependent modules first (order matters!)
echo "Loading dependent modules..."
modprobe wmi
modprobe platform_profile
modprobe pcc_acpi 2>/dev/null || true

# Load ideapad_laptop FIRST
echo "Loading ideapad_laptop..."
modprobe ideapad_laptop

# Wait for ideapad_acpi to be available
sleep 1

# Bind ideapad_acpi to VPC2004:00 BEFORE loading legion
echo "Binding ideapad_acpi to VPC2004:00..."
if [ -d "/sys/bus/platform/drivers/ideapad_acpi" ]; then
    echo "VPC2004:00" > /sys/bus/platform/drivers/ideapad_acpi/bind 2>/dev/null || true
fi

# Now load legion_laptop
echo "Loading legion_laptop..."
modprobe legion_laptop force=1

# Wait for legion to initialize
sleep 1

# FIX: PNP0C09:00 might be bound to acpi-ec instead of legion
# Unbind from acpi-ec and bind to legion
echo "Fixing PNP0C09:00 binding..."
if [ -d "/sys/bus/platform/drivers/acpi-ec" ]; then
    # Check if PNP0C09:00 is bound to acpi-ec
    if [ -L "/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/driver" ]; then
        CURRENT_DRIVER=$(readlink /sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/driver 2>/dev/null || echo "")
        if [[ "$CURRENT_DRIVER" == *"acpi-ec"* ]]; then
            echo "Unbinding PNP0C09:00 from acpi-ec..."
            echo -n "PNP0C09:00" > /sys/bus/platform/drivers/acpi-ec/unbind 2>/dev/null || true
        fi
    fi
fi

# Bind PNP0C09:00 to legion driver
echo "Binding PNP0C09:00 to legion driver..."
if [ -d "/sys/bus/platform/drivers/legion" ]; then
    echo -n "PNP0C09:00" > /sys/bus/platform/drivers/legion/bind 2>/dev/null || true
fi

sleep 1

# Install systemd service for boot-time fix
echo "Installing systemd service for boot-time fix..."
cp "$(dirname "$0")/legion-driver-fix.service" /etc/systemd/system/ 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true
systemctl enable legion-driver-fix.service 2>/dev/null || true

# Restart legiond
echo "Restarting legiond service..."
systemctl restart legiond 2>/dev/null || true

# Verify everything loaded
if lsmod | grep -q "legion_laptop"; then
    echo ""
    echo "=========================================="
    echo "✅ SUCCESS! All modules loaded"
    echo "=========================================="
    echo ""
    echo "Testing features..."
    echo ""
    echo "=== Legion Driver (PNP0C09:00) ==="
    echo "Rapidcharge: $(cat /sys/bus/platform/drivers/legion/PNP0C09:00/rapidcharge 2>/dev/null || echo 'N/A')"
    echo "Touchpad: $(cat /sys/bus/platform/drivers/legion/PNP0C09:00/touchpad 2>/dev/null || echo 'N/A')"
    echo "Fan speed: $(cat /sys/bus/platform/drivers/legion/PNP0C09:00/hwmon/hwmon*/fan1_input 2>/dev/null | head -1 || echo 'N/A') RPM"
    echo "Power mode: $(cat /sys/bus/platform/drivers/legion/PNP0C09:00/powermode 2>/dev/null || echo 'N/A')"
    echo ""
    echo "=== Ideapad_acpi (VPC2004:00) ==="
    echo "Conservation: $(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode 2>/dev/null || echo 'N/A')"
    echo "Fn Lock: $(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/fn_lock 2>/dev/null || echo 'N/A')"
    echo "Camera: $(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/camera_power 2>/dev/null || echo 'N/A')"
    echo "USB Charging: $(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/usb_charging 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Open LLL GUI to verify all features are available!"
else
    echo ""
    echo "❌ FAILED! Module did not load. Check dmesg for errors."
    echo "Run: sudo dmesg | grep legion"
    exit 1
fi
