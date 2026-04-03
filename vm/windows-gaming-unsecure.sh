#!/bin/bash

################################################################################
# VM
################################################################################

VM_NAME="windows-gaming-unsecure"
RAM="24G"
THREADS="16"

################################################################################
# DISQUES
################################################################################

DATA="/mnt/nvme2/vm/windows-gaming-data.qcow2"
DISK="/mnt/nvme2/vm/windows-gaming-unsecure.qcow2"

################################################################################
# FIRMWARE / OVMF
################################################################################

OVMF_CODE="/mnt/nvme2/vm/ovmf/OVMF_CODE.4m.fd"
OVMF_VARS="/mnt/nvme2/vm/ovmf/OVMF_VARS_UNSECURE.fd"

source "$SCRIPT_DIR/vm/src/windows-gaming.sh"

