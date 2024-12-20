#!/bin/bash

if [ "root" != "$USER" ]; then
    echo "must be run as root"
    exit 1
fi

apt update -y
apt upgrade -y

apt install -y curl vim jq

## 1. Setup tailscale
if [ ! -f "/usr/bin/tailscale" ]; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi
tailscale up --ssh

## 2. Install docker
if [ ! -f "/usr/bin/docker" ]; then
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
if [ -f "/usr/bin/otelcol-contrib" ]; then
    dpkg -r otelcol-contrib
fi
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.116.1/otelcol-contrib_0.116.1_linux_amd64.deb
dpkg -i otelcol-contrib_0.116.1_linux_amd64.deb

mv /etc/otelcol-contrib/config.yaml /etc/otelcol-contrib/config.orig.yaml
ln -s /usr/local/etc/otel/otel_collector.yaml /etc/otelcol-contrib/config.yaml
systemctl restart otelcol-contrib
mkdir -p /var/log/homelab

## 4. Install mahogany
# TODO fix
# wget https://github.com/mpoegel/mahogany/releases/download/v0.0.2/mahogany_Linux_x86_64._0.0.2.tar.gz
# tar xzfv mahogany_Linux_x86_64._0.0.2.tar.gz -C /
# service mahogany restart

## 5. Set reboot cycle
crontab /usr/local/etc/cron/crontab

## 6. Setup logrotate
ln -s /usr/local/etc/logrotate/homelab /etc/logrotate.d/homelab
