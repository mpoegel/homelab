#!/bin/bash

# 1. Install keycloak
KEYCLOAK_VERSION="26.2.2"
wget "https://github.com/keycloak/keycloak/releases/download/${KEYCLOAK_VERSION}/keycloak-${KEYCLOAK_VERSION}.tar.gz"
mkdir -p "keycloak"
tar -xvf "keycloak-${KEYCLOAK_VERSION}.tar.gz" -C /usr/local --strip-components=1
rm "keycloak-${KEYCLOAK_VERSION}.tar.gz"

# 2. Setup certbot
apt install -y python3 python3-venv libaugeas0
python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot
ln -s /opt/certbot/bin/certbot /usr/bin/certbot
/opt/certbot/bin/pip install certbot-dns-cloudflare

certbot certonly --cert-name poegel.dev -d "login.poegel.dev" \
    --dns-cloudflare --dns-cloudflare-credentials=cloudflare.ini

# 3. Install java
apt-get install -y openjdk-21-jre

# 4. Initialize keycloak
cp /usr/local/etc/keycloak/keycloak.conf /usr/local/conf/keycloak.conf
mkdir -p /usr/local/themes/pizza/login/resources/{css,img}
cp /usr/local/etc/keycloak/pizza-background.png /usr/local/themes/pizza/login/resources/img/
cp /usr/local/etc/keycloak/pizza.css /usr/local/themes/pizza/login/resources/css/
cp /usr/local/etc/keycloak/theme.properties /usr/local/themes/pizza/login/

ln -s /usr/local/etc/systemd/system/keycloak.service /etc/systemd/system/keycloak.service
systemctl enable keycloak
service keycloak start

/usr/local/bin/kc.sh bootstrap-admin user

# If migrating from a previous install,
# /usr/local/bin/kc.sh export
# /usr/local/bin/kc.sh import
