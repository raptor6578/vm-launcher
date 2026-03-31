################################################################################
# VM
################################################################################

RAM="24G"
THREADS="16"

################################################################################
# OVMF
################################################################################

OVMF_CODE="/mnt/nvme2/vm/ovmf/OVMF_CODE_4M.ms.fd"
OVMF_VARS="/mnt/nvme2/vm/ovmf/OVMF_VARS_SECURE.fd"

################################################################################
# STORAGE
################################################################################

SWTPM_SOCKET="/mnt/nvme2/vm/tpm"
DATA="/mnt/nvme2/vm/gaming-windows-data.qcow2"
DISK="/mnt/nvme2/vm/gaming-windows-secure.qcow2"

################################################################################
# GPU - Passthrough
################################################################################

PCI_GPU="0000:01:00.0"
PCI_GPU_AUDIO="0000:01:00.1"

################################################################################
# USB — Contrôleur passthrough complet (Corsair / NZXT / interne)
################################################################################

PCI_USB_CONTROLLER="0000:0e:00.0"

################################################################################
# USB — Razer / Astro (passthrough individuel)
################################################################################

USB_RAZER_KEYBOARD="1532:028d"   # Razer BlackWidow V4 Pro
USB_RAZER_MOUSE="1532:00ab"      # Razer Basilisk V3 Pro
USB_RAZER_DOCK="1532:00a4"       # Razer Mouse Dock Pro
USB_RAZER_PAD="1532:0c05"        # Razer Strider Chroma

USB_ASTRO_A50="9886:002c"        # Astro A50 (Base + audio USB)

USB_PASSTHROUGH_DEVICES=(
  "$USB_RAZER_KEYBOARD"
  "$USB_RAZER_MOUSE"
  "$USB_RAZER_DOCK"
  "$USB_RAZER_PAD"
  "$USB_ASTRO_A50"
)

##################################################################################
# QEMU - Arguments
##################################################################################

USB_ARGS=()
for dev in "${USB_PASSTHROUGH_DEVICES[@]}"; do
  vid=${dev%%:*}
  pid=${dev##*:}
  USB_ARGS+=(-device "usb-host,vendorid=0x$vid,productid=0x$pid")
done

QEMU_ARGS=(
    -enable-kvm
    -machine "type=q35,accel=kvm,smm=on,kernel_irqchip=on"
    -rtc "base=localtime,clock=host,driftfix=slew"
    -nodefaults
    -smbios "type=1,manufacturer=ASUS,product=ROG-STRIX-Z790-E-GAMING,version=1.0,serial=123456789"
    -smp "$THREADS"
    -cpu "host,svm=on,kvm=off,hv_relaxed,hv_vapic,hv_spinlocks=0xffffffff,hv_vpindex,hv_runtime,hv_synic,hv_stimer,hv_frequencies,hv_time,hv_avic"
    -global "ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off"
    -global "ICH9-LPC.disable_s3=1"
    -global "ICH9-LPC.disable_s4=1"
    -global "driver=cfi.pflash01,property=secure,value=on"
    -m "$RAM"
    -vga "none"
    -display "none"
    -device "qemu-xhci,id=usb-bus"
    "${USB_ARGS[@]}"
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
    -drive "if=pflash,format=raw,file=$OVMF_VARS"
    -drive "file=$DISK,if=none,id=disk0,format=qcow2"
    -drive "file=$DATA,if=none,id=data0,format=qcow2"
    -netdev "user,id=net0"
    -device "e1000e,netdev=net0,mac=00:1A:2B:3C:4D:5E"
    -device "virtio-blk-pci,drive=disk0,serial=Samsung_980PRO"
    -device "virtio-blk-pci,drive=data0,serial=Samsung_Data"
    -device "vfio-pci,host=$PCI_GPU,multifunction=on"
    -device "vfio-pci,host=$PCI_GPU_AUDIO"
    -device "vfio-pci,host=$PCI_USB_CONTROLLER"
    -chardev "socket,id=chrtpm,path=$SWTPM_SOCKET/swtpm-sock"
    -tpmdev "emulator,id=tpm0,chardev=chrtpm"
    -device "tpm-tis,tpmdev=tpm0"
    -boot "order=c"
    -monitor "stdio"
)

##################################################################################
# DEMARRAGE 
##################################################################################

stop_services 
pci_rebind "$PCI_GPU" vfio-pci 
pci_rebind "$PCI_GPU_AUDIO" vfio-pci 
pci_rebind "$PCI_USB_CONTROLLER" vfio-pci 
start_swtpm "$SWTPM_SOCKET"
start_qemu 

##################################################################################
# ARRET 
##################################################################################

cleanup() {
  stop_swtpm
  pci_rebind "$PCI_USB_CONTROLLER" xhci_hcd 
  pci_rebind "$PCI_GPU" nvidia 
  pci_rebind "$PCI_GPU_AUDIO" snd_hda_intel 
  start_services 
}



