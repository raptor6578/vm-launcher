#!/usr/bin/env bash
set -euo pipefail

SOCK="/run/vm.sock"
TIMEOUT=30

# Demande shutdown propre via QMP
if [ -S "$SOCK" ]; then
  echo "system_powerdown" | socat - UNIX-CONNECT:"$SOCK" || true
fi

# Attente de l'arrêt réel du process QEMU
for ((i=0; i<TIMEOUT*10; i++)); do
  if ! pgrep -f "qemu-system-x86_64.*-name windows-utility" >/dev/null; then
    exit 0
  fi
  sleep 0.1
done

echo "Timeout waiting for windows-utility shutdown" >&2
exit 1
