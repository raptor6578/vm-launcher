#!/usr/bin/env bash

echo
echo "======================================"
echo "        VM Selection"
echo "======================================"
echo "1) Windows gaming secure"
echo "2) Windows gaming unsecure"
echo

while true; do
    read -rp "Select VM [1-2] (default: 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1) vm="windows-gaming-secure"; break ;;
        2) vm="windows-gaming-unsecure"; break ;;
        *) echo "Invalid choice" ;;
    esac
done

sudo systemctl start "vm-launcher@$vm"
read -rp "Press Enter to close..."
