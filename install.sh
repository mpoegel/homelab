#!/bin/bash

HOMELAB_VERSION="v0.0.4"

if [ "root" != "$USER" ]; then
    echo "must be run as root"
    exit 1
fi

## 0. Install homelab files
wget "https://github.com/mpoegel/homelab/releases/latest/download/homelab_${HOMELAB_VERSION}.tar.gz"
tar xzfv "homelab_${HOMELAB_VERSION}.tar.gz" -C /

. /usr/local/bin/homelab_functions.sh

TEMP=$(getopt -o "e:" --long "env" -n "install.sh" -- "$@")
eval set -- "$TEMP"
unset TEMP

ENVIRONMENT="lab"

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

## 1. Install environment
if [ "lab" == "$ENVIRONMENT" ]; then
    log_info "installing lab environment"
    exec /usr/local/sbin/setup_ubuntu.sh
elif [ "edge" == "$ENVIRONMENT" ]; then
    log_info "installing edge environment"
    exec /usr/local/sbin/setup_edge.sh
else
    log_error "invalid environment: ${ENVIRONMENT}"
fi
