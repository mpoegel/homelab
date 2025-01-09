#!/bin/bash

if [ "root" != "$USER" ]; then
    echo "must be run as root"
    exit 1
fi

. /etc/os-release
. /usr/local/bin/homelab_functions.sh

TEMP=$(getopt -o "e:" --long "env" -n "setup_envoy.sh" -- "$@")
eval set -- "$TEMP"
unset TEMP

ENVIRONMENT="edge"

while true; do
    case "$1" in
        "-e"|"--env")
            ENVIRONMENT="$2"
            shift
            continue
        ;;
        "--")
            shift
            break
        ;;
        *)
            log_error "Internal error!"
        ;;
    esac
done

if [ "$NAME" == "Oracle Linux Server" ]; then
    yum upgrade
    yum install -y curl vim jq snapd
else
    apt update -y
    apt upgrade -y
    apt install -y curl vim jq
fi

## 1. Setup tailscale
if [ ! -f "/usr/bin/tailscale" ]; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi
tailscale up --ssh

# 2. Setup certbot
if [ "$NAME" == "Oracle Linux Server" ]; then
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
    snap set certbot trust-plugin-with-root=ok
    snap install certbot-dns-cloudflare
else
    apt install -y python3 python3-venv libaugeas0
    python3 -m venv /opt/certbot/
    /opt/certbot/bin/pip install --upgrade pip
    /opt/certbot/bin/pip install certbot
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot
    /opt/certbot/bin/pip install certbot-dns-cloudflare
fi

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

if [ -f "/usr/local/etc/envoy/envoy.yaml" ]; then
    rm /usr/local/etc/envoy/envoy.yaml
fi

ln -s /usr/local/etc/systemd/system/envoy.service /etc/systemd/system/envoy.service

if [ "edge" == "$ENVIRONMENT" ]; then
    ln -s /usr/local/etc/envoy/edge_envoy.yaml /usr/local/etc/envoy/envoy.yaml
elif [ "home" == "$ENVIRONMENT" ]; then
    ln -s /usr/local/etc/envoy/home_envoy.yaml /usr/local/etc/envoy/envoy.yaml
else
    log_error "invalid environment: ${ENVIRONMENT}"
fi

systemctl enable envoy
service envoy start

## 4. Set reboot cycle
crontab /usr/local/etc/cron/crontab
