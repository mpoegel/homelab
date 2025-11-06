#!/bin/bash

. /etc/os-release
. /usr/local/bin/homelab_functions.sh

if [[ $EUID -ne 0 ]]; then
    log_error "must be run as root"
fi

TEMP=$(getopt -o "e:" --long "env:,version:,no-tailscale" -n "setup_envoy.sh" -- "$@")
eval set -- "$TEMP"
unset TEMP

ENVIRONMENT="edge"
ENVOY_VERSION="1.36.2"
NO_TAILSCALE=false

while true; do
    case "$1" in
        "-e"|"--env")
            ENVIRONMENT="$2"
            shift 2
            continue
        ;;
        "--version")
            ENVOY_VERSION="$2"
            shift 2
            continue
        ;;
        "--no-tailscale")
            NO_TAILSCALE=true
            shift 1
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

if [[ "$NAME" == "Oracle Linux Server" ]]; then
    yum upgrade
    yum install -y epel-release
    yum install -y curl vim jq snapd wget cronie
else
    apt update -y
    apt upgrade -y
    apt install -y curl vim jq wget cron
fi

## 1. Setup tailscale
if [[ $NO_TAILSCALE == false ]]; then
    if [ ! -f "/usr/bin/tailscale" ]; then
        curl -fsSL https://tailscale.com/install.sh | sh
        tailscale up --ssh
    fi
fi

# 2. Setup certbot
if [[ "$NAME" == "Oracle Linux Server" ]]; then
    snap install --classic certbot
    if [ ! -f /usr/bin/certbot ]; then
        ln -s /snap/bin/certbot /usr/bin/certbot
    fi
    snap set certbot trust-plugin-with-root=ok
    snap install certbot-dns-cloudflare
else
    apt install -y python3 python3-venv libaugeas0
    python3 -m venv /opt/certbot/
    /opt/certbot/bin/pip install --upgrade pip
    /opt/certbot/bin/pip install --upgrade certbot
    if [ ! -f /usr/bin/certbot ]; then
        ln -s /opt/certbot/bin/certbot /usr/bin/certbot
    fi
    /opt/certbot/bin/pip install certbot-dns-cloudflare
fi

# 3. Install envoy
ENVOY_URL="https://github.com/envoyproxy/envoy/releases/download/v${ENVOY_VERSION}/envoy-${ENVOY_VERSION}-linux-x86_64"
ENVOY_OUT="/usr/local/bin/envoy-${ENVOY_VERSION}"
if [ "$NAME" == "Oracle Linux Server" ]; then
    ENVOY_URL="https://github.com/envoyproxy/envoy/releases/download/v${ENVOY_VERSION}/envoy-${ENVOY_VERSION}-linux-aarch_64"
fi

if ! wget "${ENVOY_URL}" -O "${ENVOY_OUT}"; then
    rm "${ENVOY_OUT}"
    log_error "unable to download envoy"
fi

chmod 771 "${ENVOY_OUT}"
if [ -f /usr/local/bin/envoy ]; then
    rm /usr/local/bin/envoy
fi
ln -s "${ENVOY_OUT}" /usr/local/bin/envoy

if [ -f "/usr/local/etc/envoy/envoy.yaml" ]; then
    rm /usr/local/etc/envoy/envoy.yaml
fi

if [ ! -f "/etc/systemd/system/envoy.service" ]; then
    ln -s /usr/local/etc/systemd/system/envoy.service /etc/systemd/system/envoy.service
fi

if [ ! -f "/usr/local/etc/envoy/envoy.yaml" ]; then
    if [ "edge" == "$ENVIRONMENT" ]; then
        ln -s /usr/local/etc/envoy/edge_envoy.yaml /usr/local/etc/envoy/envoy.yaml
    elif [ "home" == "$ENVIRONMENT" ]; then
        ln -s /usr/local/etc/envoy/home_envoy.yaml /usr/local/etc/envoy/envoy.yaml
    else
        log_error "invalid environment: ${ENVIRONMENT}"
    fi
fi

if ! systemctl daemon-reload && systemctl enable --now envoy; then
    log_warn "unable to bounce envoy"
fi

## 4. Set reboot cycle
crontab /usr/local/etc/cron/crontab

log_info "setup complete"
