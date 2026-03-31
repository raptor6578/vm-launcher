#!/usr/bin/env bash

################################################################################
# SWTPM
################################################################################


start_swtpm() {
    local swtpm_socket="$1" 
    sudo mkdir -p "$swtpm_socket"
    sudo swtpm socket \
        --tpmstate dir="$swtpm_socket" \
        --ctrl type=unixio,path="$swtpm_socket/swtpm-sock" \
        --log level=20 \
        --tpm2 \
        >/dev/null 2>&1 &
}

stop_swtpm() {
    sudo pkill swtpm >/dev/null 2>&1 || true
}
