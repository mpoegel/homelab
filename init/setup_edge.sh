#!/bin/bash

if [ "root" != "$USER" ]; then
    echo "must be run as root"
    exit 1
fi

. /etc/os-release

yum upgrade
yum install -y curl vim jq

## 1. Setup tailscale
if [ ! -f "/usr/bin/tailscale" ]; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi
tailscale up --ssh

# 2. Setup certbot
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# 3. Install envoy
if [ "$NAME" == "Oracle Linux Server" ]; then
    wget https://github.com/envoyproxy/envoy/releases/download/v1.32.2/envoy-1.32.2-linux-aarch_64 \
        -O /usr/local/bin/envoy-1.32.2
else
    wget https://github.com/envoyproxy/envoy/releases/download/v1.32.2/envoy-1.32.2-linux-x86_64 \
        -O /usr/local/bin/envoy-1.32.2
fi

chmod 771 /usr/local/bin/envoy-1.32.2
rm /usr/local/bin/envoy
ln -s /usr/local/bin/envoy-1.32.2 /usr/local/bin/envoy

systemctl enable envoy
service envoy start

## 4. Set reboot cycle
crontab /usr/local/etc/cron/crontab
