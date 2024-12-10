#!/bin/bash
# Update and reboot the host

. bin/homelab_functions.sh || . /usr/local/bin/homelab_functions.sh
. /etc/os-release

if [ "root" != "$USER" ]; then
    log_error "must be run as root"
fi

log_info "starting update and restart after delay"

sleep $((RANDOM % 5))

if [ "$NAME" == "Ubuntu" ]; then
    apt update -y
    apt upgrade -y
elif [ "$NAME" == "Oracle Linux Server" ]; then
    yum upgrade
fi

reboot
