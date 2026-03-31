#!/usr/bin/env bash

################################################################################
# PCI
################################################################################

sysfs_write() {
    echo "$1" | sudo tee "$2" >/dev/null
}
pci_rebind() {
    local device="$1"
    local driver="$2"
    local devpath="/sys/bus/pci/devices/$device"

    if [[ -L "$devpath/driver" ]]; then
        sysfs_write "$device" "$devpath/driver/unbind"
    fi

    sysfs_write "$driver" "$devpath/driver_override"
    sysfs_write "$device" /sys/bus/pci/drivers_probe

    if [[ -L "$devpath/driver" ]] && [[ "$(basename "$(readlink "$devpath/driver")")" == "$driver" ]]; then
        sysfs_write "" "$devpath/driver_override"
    else
        echo "Error: $device failed to bind to $driver" >&2
        return 1
    fi
}
