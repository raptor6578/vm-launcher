#!/usr/bin/env bash

echo
echo "======================================"
echo "        VM Selection"
echo "======================================"
echo "1) Secure Windows VM"
echo "2) Unsecure Windows VM"
echo

while true; do
    read -rp "Select VM [1-2] (default: 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1) vm="windows-secure"; break ;;
        2) vm="windows-unsecure"; break ;;
        *) echo "Invalid choice" ;;
    esac
done

sudo systemctl start "vm-launcher@$vm"
read -rp "Press Enter to close..."
