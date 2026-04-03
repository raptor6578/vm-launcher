#!/usr/bin/env bash

#####################################################################
# SERVICES
#####################################################################

stop_services() {
    sudo systemctl stop greetd
    sudo systemctl stop windows-utility
}

start_services() {
    sudo systemctl start greetd
    sudo systemctl start windows-utility
}

