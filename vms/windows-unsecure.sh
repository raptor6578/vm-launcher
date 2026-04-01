################################################################################
# VM
################################################################################

VM_NAME="windows-unsecure"
RAM="24G"
THREADS="16"

################################################################################
# FIRMWARE / OVMF
################################################################################

OVMF_CODE="/mnt/nvme2/vm/ovmf/OVMF_CODE.4m.fd"
OVMF_VARS="/mnt/nvme2/vm/ovmf/OVMF_VARS_UNSECURE.fd"

################################################################################
# TPM / Runtime
################################################################################

SWTPM_SOCKET="/mnt/nvme2/vm/tpm"

################################################################################
# DISQUES
################################################################################

DATA="/mnt/nvme2/vm/gaming-windows-data.qcow2"
DISK="/mnt/nvme2/vm/gaming-windows-unsecure.qcow2"

################################################################################
# PCI passthrough
################################################################################

PCI_GPU="0000:01:00.0"
PCI_GPU_AUDIO="0000:01:00.1"
PCI_USB_CONTROLLER="0000:0e:00.0"

################################################################################
# USB (passthrough individuel)
################################################################################

USB_PASSTHROUGH_DEVICES=(
  "1532:028d"  # Razer BlackWidow V4 Pro
  "1532:00ab"  # Razer Basilisk V3 Pro
  "1532:00a4"  # Razer Mouse Dock Pro
  "1532:0c05"  # Razer Strider Chroma
  "9886:002c"  # Astro A50
)

USB_ARGS=()
for dev in "${USB_PASSTHROUGH_DEVICES[@]}"; do
  vid=${dev%%:*}
  pid=${dev##*:}
  USB_ARGS+=(-device "usb-host,vendorid=0x$vid,productid=0x$pid")
done

################################################################################
# CPU Arguments / Nested virtualization / Anti-VM detection
# ⚠️ Ne pas modifier sans retester nested hypervisors
################################################################################

CPU=(
  ############################################
  # Utilise exactement le CPU physique du host
  # → meilleures performances possibles
  # → expose toutes les features CPU au guest
  # → recommandé pour GPU passthrough + gaming
  ############################################
  "host"

  ############################################
  # Active SVM (AMD virtualization)
  # → nécessaire pour nested hypervisor dans Windows
  # → requis pour Hyper-V / anti-cheat utilisant virtualization
  ############################################
  "svm=on"

  ############################################
  # Cache la présence de KVM au guest
  # → important pour anti-VM detection
  # → certains anti-cheat / DRM détectent "KVM"
  # → réduit aussi certains comportements spécifiques KVM
  ############################################
  "kvm=off"

  ############################################
  # Hyper-V Enlightenment : relaxed timing
  # → réduit les VM exits liés aux timers watchdog
  # → améliore stabilité Windows guest
  ############################################
  "hv_relaxed"

  ############################################
  # Virtual APIC Hyper-V
  # → réduit les VM exits pour interruptions CPU
  # → améliore latence CPU / scheduling
  # → important pour gaming
  ############################################
  "hv_vapic"

  ############################################
  # Spinlock Hyper-V
  # → évite que Windows boucle trop longtemps sur locks CPU
  # → 0xffffffff = spin longtemps (moins de VM exits)
  # → parfois mieux pour nested hypervisor
  # → peut être testé avec 0x0fff pour réduire latence
  ############################################
  "hv_spinlocks=0xffffffff"

  ############################################
  # Virtual Processor Index
  # → permet à Windows de mieux gérer multi-core
  # → réduit overhead SMP
  # → recommandé pour VM gaming multi-core
  ############################################
  "hv_vpindex"

  ############################################
  # Runtime reporting Hyper-V
  # → permet à Windows d’optimiser scheduler
  # → améliore distribution CPU
  ############################################
  "hv_runtime"

  ############################################
  # Synthetic Interrupt Controller
  # → nécessaire pour timers Hyper-V modernes
  # → important pour nested hypervisor
  # → améliore latence globale
  ############################################
  "hv_synic"

  ############################################
  # Synthetic timers Hyper-V
  # → évite fallback HPET (lent)
  # → très important pour latence gaming
  # → souvent gros gain
  ############################################
  "hv_stimer"

  ############################################
  # CPU frequency reporting
  # → permet à Windows de voir fréquence CPU correcte
  # → améliore scheduler Windows
  # → évite mauvais scaling CPU
  ############################################
  "hv_frequencies"

  ############################################
  # Hyper-V time source
  # → améliore précision timers
  # → réduit jitter frametime
  # → important pour jeux sensibles
  ############################################
  "hv_time"

  ############################################
  # AVIC (AMD Virtual Interrupt Controller)
  # → réduit VM exits pour interrupts
  # → peut réduire latence input
  # → parfois gain important sur Ryzen
  # → parfois micro-stutter selon CPU
  ############################################
  "hv_avic"
)

CPU_ARGS=$(IFS=, ; echo "${CPU[*]}")

################################################################################
# QEMU - Arguments
################################################################################

QEMU_ARGS=(
    ############################################
    # Nom de la VM
    ############################################
    -name "$VM_NAME"

    ############################################
    # Accélération / Machine
    ############################################
    -enable-kvm
    -machine "type=q35,accel=kvm,smm=on,kernel_irqchip=on"

    ############################################
    # Horloge / Timing
    ############################################
    -rtc "base=localtime,clock=host,driftfix=slew"

    ############################################
    # Configuration minimale (pas de defaults QEMU)
    ############################################
    -nodefaults

    ############################################
    # SMBIOS spoof (machine physique crédible)
    # Utile pour anti-cheat / nested hypervisor
    ############################################
    -smbios "type=1,manufacturer=ASUS,product=ROG-STRIX-Z790-E-GAMING,version=1.0,serial=123456789"

    ############################################
    # CPU
    ############################################
    -smp "$THREADS"
    -cpu "$CPU"

    ############################################
    # ACPI tweaks (stabilité passthrough GPU / USB)
    ############################################
    -global "ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off"
    -global "ICH9-LPC.disable_s3=1"
    -global "ICH9-LPC.disable_s4=1"

    ############################################
    # RAM
    ############################################
    -m "$RAM"

    ############################################
    # Pas de GPU virtuel (GPU passthrough uniquement)
    ############################################
    -vga "none"
    -display "none"

    ############################################
    # USB virtuel (clavier, souris, casque, dock)
    ############################################
    -device "qemu-xhci,id=usb-bus"
    "${USB_ARGS[@]}"

    ############################################
    # UEFI / OVMF
    ############################################
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
    -drive "if=pflash,format=raw,file=$OVMF_VARS"

    ############################################
    # Disques
    ############################################
    -drive "file=$DISK,if=none,id=disk0,format=qcow2"
    -drive "file=$DATA,if=none,id=data0,format=qcow2"

    ############################################
    # Réseau (Intel e1000e pour compat anti-cheat)
    ############################################
    -netdev "user,id=net0"
    -device "e1000e,netdev=net0,mac=00:1A:2B:3C:4D:5E"

    ############################################
    # Disques VirtIO (performance stockage)
    ############################################
    -device "virtio-blk-pci,drive=disk0,serial=Samsung_980PRO"
    -device "virtio-blk-pci,drive=data0,serial=Samsung_Data"

    ############################################
    # GPU Passthrough
    ############################################
    -device "vfio-pci,host=$PCI_GPU,multifunction=on"
    -device "vfio-pci,host=$PCI_GPU_AUDIO"

    ############################################
    # USB Controller passthrough (AIO / FAN / RGB)
    ############################################
    -device "vfio-pci,host=$PCI_USB_CONTROLLER"

    ############################################
    # TPM 2.0 (Windows 11)
    ############################################
    -chardev "socket,id=chrtpm,path=$SWTPM_SOCKET/swtpm-sock"
    -tpmdev "emulator,id=tpm0,chardev=chrtpm"
    -device "tpm-tis,tpmdev=tpm0"

    ############################################
    # Boot
    ############################################
    -boot "order=c"

    ############################################
    # Console QEMU
    ############################################
    -monitor "stdio"
)

##################################################################################
# DEMARRAGE 
##################################################################################

start_vm() {
  stop_services 
  pci_rebind "$PCI_GPU" vfio-pci 
  pci_rebind "$PCI_GPU_AUDIO" vfio-pci 
  pci_rebind "$PCI_USB_CONTROLLER" vfio-pci 
  start_swtpm "$SWTPM_SOCKET"
  start_qemu 
}

##################################################################################
# ARRET 
##################################################################################

cleanup() {
  stop_swtpm || true
  pci_rebind "$PCI_USB_CONTROLLER" xhci_hcd || true
  pci_rebind "$PCI_GPU" nvidia || true
  pci_rebind "$PCI_GPU_AUDIO" snd_hda_intel || true
  start_services || true
}

trap cleanup EXIT INT TERM

start_vm
