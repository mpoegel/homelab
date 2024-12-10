#!/bin/bash

if [ "root" != "$USER" ]; then
    echo "must be run as root"
    exit 1
fi

apt update -y
apt upgrade -y

## 1. Setup tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --ssh

## 2. Install docker
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

## 3. Install mahogany
wget https://github.com/mpoegel/mahogany/releases/download/latest/mahogany_Linux_x86_64.tar.gz
tar xzfv mahogany_Linux_x86_64.tar.gz -C /
service mahogany restart

## 4. Set reboot cycle
crontab /usr/local/etc/cron/crontab
