#!/usr/bin/env bash
set -euo pipefail

VM_NAME="${1:?Usage: $0 <vm-name>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_CONF="$SCRIPT_DIR/vm/$VM_NAME.sh"

[[ -f "$VM_CONF" ]] || { echo "VM config not found: $VM_CONF" >&2; exit 1; }

sudo modprobe vfio-pci
source "$SCRIPT_DIR/src/pci.sh"
source "$SCRIPT_DIR/src/services.sh"
source "$SCRIPT_DIR/src/qemu-common.sh"
source "$SCRIPT_DIR/src/swtpm.sh"
source "$VM_CONF"

