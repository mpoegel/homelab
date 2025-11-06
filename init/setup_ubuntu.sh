#!/bin/bash

. /usr/local/bin/homelab_functions.sh

if [[ $EUID -ne 0 ]]; then
    log_warn "must be run as root"
fi

TEMP=$(getopt --long "no-docker,no-tailscale,otel-version:,mahogany-version:" -n "setup_ubuntu.sh" -- "$@")
eval set -- "$TEMP"
unset TEMP

NO_DOCKER=false
NO_TAILSCALE=false
OTELCOL_VERSION="0.138.0"
MAHOGANY_VERSION="0.0.4"

while true; do
    case "$1" in
        "--no-docker")
            NO_DOCKER=true
            shift 1
            continue
        ;;
        "--no-tailscale")
            NO_TAILSCALE=true
            shift 1
            continue
        ;;
        "--otel-version")
            OTELCOL_VERSION="$2"
            shift 2
            continue
        ;;
        "--mahogany-version")
            MAHOGANY_VERSION="$2"
            shift 2
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

apt update -y
apt upgrade -y
apt install -y curl vim jq cron wget gettext-base

## 1. Setup tailscale
if [[ $NO_TAILSCALE == false ]]; then
    if [ ! -f "/usr/bin/tailscale" ]; then
        curl -fsSL https://tailscale.com/install.sh | sh
        tailscale up --ssh
    fi
fi

## 2. Install docker
if [[ $NO_DOCKER == false && ! -f "/usr/bin/docker" ]]; then
    # Add Docker's official GPG key:
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y

    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

## 3. Install OTel Collector
installed_otelcol_version=$(dpkg-query -W -f='${Version}' otelcol-contrib 2>/dev/null)
if [[ "$installed_otelcol_version" != "$OTELCOL_VERSION" ]]; then
    if [ -f "/usr/bin/otelcol-contrib" ]; then
        dpkg -r otelcol-contrib
    fi
    OTEL_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.deb"
    if ! wget "${OTEL_URL}"; then
        log_error "unable to download otelcol"
    fi
    if ! dpkg -i "otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.deb"; then
        log_error "unstable to install otelcol"
    fi
    rm "otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.deb"
else
    log_info "skipping otelcol install"
fi

mv /etc/otelcol-contrib/config.yaml /etc/otelcol-contrib/config.orig.yaml
if [ ! -f "/etc/otelcol-contrib/config.yaml" ]; then
    ln -s /usr/local/etc/otel/otel_collector.yaml /etc/otelcol-contrib/config.yaml
fi
mkdir -p /var/log/homelab
if [ ! -f "/etc/logrotate.d/homelab" ]; then
    ln -s /usr/local/etc/logrotate/homelab /etc/logrotate.d/homelab
fi
if ! systemctl daemon-reload && systemctl enable --now otelcol-contrib ; then
    log_warn "unable to restart otelcol"
fi

## 4. Install mahogany
MAHOGANY_URL="https://github.com/mpoegel/mahogany/releases/download/v${MAHOGANY_VERSION}/mahogany_Linux_x86_64_${MAHOGANY_VERSION}.tar.gz"
if ! wget "${MAHOGANY_URL}"; then
    log_error "unable to download mahogany"
fi

tar xzfv "mahogany_Linux_x86_64_${MAHOGANY_VERSION}.tar.gz" -C /
rm "mahogany_Linux_x86_64_${MAHOGANY_VERSION}.tar.gz"

if [ ! -f "/etc/systemd/system/mahogany.agent.service" ]; then
    ln -s /usr/local/etc/mahogany/mahogany.agent.service /etc/systemd/system/mahogany.agent.service
fi
cat /etc/mahogany/.env | envsubst > /etc/mahogany/.env

if ! systemctl daemon-reload && systemctl enable --now mahogany.agent; then
    log_warn "unable to restart mahogany"
fi

## 5. Set reboot cycle
crontab /usr/local/etc/cron/crontab

log_info "setup complete"
