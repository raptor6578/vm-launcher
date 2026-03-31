#!/bin/bash

################################################################################
# USB — Contrôleur passthrough complet (Corsair / NZXT / interne)
################################################################################

PCI_USB_CONTROLLER="0000:0e:00.0"

################################################################################
# VM
################################################################################

RAM=2G
THREADS=2

################################################################################
# OVMF
################################################################################

OVMF_CODE="/mnt/nvme2/vm/ovmf/OVMF_CODE.4m.fd"
OVMF_VARS="/mnt/nvme2/vm/ovmf/OVMF_VARS_UTILITY.fd"

################################################################################
# STORAGE
################################################################################

DISK="/mnt/nvme2/vm/utility-windows.qcow2"
VNC=":0"

##################################################################################
# QEMU - Arguments
##################################################################################

QEMU_ARGS=(
  -enable-kvm
  -machine "type=q35,accel=kvm"
  -cpu "host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,+invtsc,kvm=on"
  -global "kvm-pit.lost_tick_policy=discard"
  -smp "$THREADS"
  -m "$RAM"
  -overcommit "mem-lock=on"
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
  -drive "if=pflash,format=raw,file=$OVMF_VARS"
  -drive "file=$DISK,if=virtio,format=qcow2,cache=writeback"
  -device "vfio-pci,host=$PCI_USB_CONTROLLER"
  -monitor "unix:/run/vm.sock,server,nowait"
  -vga "none"
  -device "virtio-vga"
  -display "vnc=$VNC"
  -device "qemu-xhci"
  -device "usb-tablet"
  -netdev "user,id=net0,hostfwd=tcp::5555-:3389"
  -device "virtio-net-pci,netdev=net0"
  -rtc "clock=host,base=localtime"
  -boot "order=c,menu=off"
)

##################################################################################
# DEMARRAGE 
##################################################################################

pci_rebind "$PCI_USB_CONTROLLER" vfio-pci 
start_qemu 

##################################################################################
# ARRET 
##################################################################################

cleanup() {
  # Le PCI ne doit pas être remonté pour l'arrêt de l'AIO
  :
}


