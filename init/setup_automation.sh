#!/bin/bash

# https://www.home-assistant.io/installation/linux#install-home-assistant-container
docker pull ghcr.io/home-assistant/home-assistant:stable
mkdir -p /usr/local/etc/homeassistant/
docker run -d --name homeassistant --privileged \
  --restart=unless-stopped \
  -e TZ=America/New_York \
  -v /usr/local/etc/homeassistant/:/config \
  -v /run/dbus:/run/dbus:ro \
  --network=host \
  ghcr.io/home-assistant/home-assistant:stable
