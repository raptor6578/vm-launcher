#!/usr/bin/env bash

SOCK="/run/vm.sock"

if [ -S "$SOCK" ]; then
  echo "system_powerdown" | socat - UNIX-CONNECT:$SOCK
  sleep 30
fi
