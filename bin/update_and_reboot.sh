#!/bin/bash
# Update and reboot the host

if [ "root" != "$USER" ]; then
    echo "must be run as root"
    exit 1
fi

echo "starting update and restart after delay"

sleep $((RANDOM % 5))

apt update -y
apt upgrade -y
reboot
