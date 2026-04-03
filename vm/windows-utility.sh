#!/bin/bash

################################################################################
# VM
################################################################################

VM_NAME="windows-utility"
RAM=2G
THREADS=2

################################################################################
# USB — Contrôleur passthrough complet (Corsair / NZXT / interne)
################################################################################

PCI_USB_CONTROLLER="0000:0e:00.0"

################################################################################
# OVMF / Runtime
################################################################################

OVMF_CODE="/mnt/nvme2/vm/ovmf/OVMF_CODE.4m.fd"
OVMF_VARS="/mnt/nvme2/vm/ovmf/OVMF_VARS_UTILITY.fd"

################################################################################
# DISQUES
################################################################################

DISK="/mnt/nvme2/vm/windows-utility.qcow2"

################################################################################
# VNC :0 → port 5900, :1 → port 5901, :2 → port 5902, :3 → port 5903
################################################################################

VNC=":0"

################################################################################
# QEMU - Arguments
################################################################################

QEMU_ARGS=(
  ############################################
  # Nom de la VM
  # → visible dans ps / monitor QEMU
  # → utile pour debug multi-VM
  ############################################
  -name "$VM_NAME"

  ############################################
  # Accélération KVM
  # → active virtualisation matérielle
  # → performances quasi natives
  ############################################
  -enable-kvm

  ############################################
  # Machine q35 moderne
  # → chipset PCIe moderne
  # → recommandé pour passthrough GPU
  # → accel=kvm = utilise KVM
  ############################################
  -machine "type=q35,accel=kvm"

  ############################################
  # CPU passthrough + Hyper-V enlightenments
  # host        → CPU physique complet
  # hv_relaxed  → améliore timers Windows
  # hv_spinlocks→ réduit contention CPU
  # hv_vapic    → optimise interruptions
  # hv_time     → timers précis
  # +invtsc     → timestamp stable
  # kvm=on      → expose KVM au guest
  ############################################
  -cpu "host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,+invtsc,kvm=on"

  ############################################
  # Timer PIT
  # → évite pertes de ticks
  # → améliore audio / gaming
  ############################################
  -global "kvm-pit.lost_tick_policy=discard"

  ############################################
  # CPU Threads
  # → nombre de vCPU
  ############################################
  -smp "$THREADS"

  ############################################
  # RAM
  ############################################
  -m "$RAM"

  ############################################
  # Memory lock
  # → empêche swap mémoire VM
  # → utile pour latence stable
  ############################################
  -overcommit "mem-lock=on"

  ############################################
  # OVMF firmware UEFI (readonly)
  # → BIOS UEFI
  ############################################
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"

  ############################################
  # OVMF variables (NVRAM)
  ############################################
  -drive "if=pflash,format=raw,file=$OVMF_VARS"

  ############################################
  # Disque principal
  # virtio      → performances élevées
  # qcow2       → snapshot support
  # writeback   → perf max (risque crash)
  ############################################
  -drive "file=$DISK,if=virtio,format=qcow2,cache=writeback"

  ############################################
  # USB controller passthrough
  # → accès USB natif
  # → faible latence périphériques
  ############################################
  -device "vfio-pci,host=$PCI_USB_CONTROLLER"

  ############################################
  # Monitor QEMU socket
  # → contrôle externe VM
  # → automation possible
  ############################################
  -monitor "unix:/run/vm.sock,server,nowait"

  ############################################
  # Désactive VGA par défaut
  ############################################
  -vga "none"

  ############################################
  # GPU virtuel virtio
  # → fallback graphique
  # → utile VNC
  ############################################
  -device "virtio-vga"

  ############################################
  # Affichage VNC
  # → accès distant VM
  ############################################
  -display "vnc=$VNC"

  ############################################
  # Contrôleur USB virtuel
  # → USB 3 virtuel
  ############################################
  -device "qemu-xhci"

  ############################################
  # Tablet USB
  # → curseur souris précis
  ############################################
  -device "usb-tablet"

  ############################################
  # Backend réseau NAT
  # → hostfwd RDP
  # host:5555 → guest:3389
  ############################################
  -netdev "user,id=net0,hostfwd=tcp::5555-:3389"

  ############################################
  # Carte réseau VirtIO
  # → performances réseau élevées
  ############################################
  -device "virtio-net-pci,netdev=net0"

  ############################################
  # Horloge
  # clock=host  → sync host
  # localtime   → recommandé Windows
  ############################################
  -rtc "clock=host,base=localtime"

  ############################################
  # Boot
  # order=c → disque
  # menu=off → pas menu boot
  ############################################
  -boot "order=c,menu=off"
)

##################################################################################
# DEMARRAGE 
##################################################################################

start_vm() {
  pci_rebind "$PCI_USB_CONTROLLER" vfio-pci 
  start_qemu 
}

start_vm

