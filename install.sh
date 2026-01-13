#!/bin/bash

USER=$(whoami)
if [ "root" != "$USER" ]; then
    echo "must be run as root"
    exit 1
fi

TEMP=$(getopt -o "e:" --long "env:,skip-update,version:" -n "install.sh" -- "$@")
eval set -- "$TEMP"
unset TEMP

ENVIRONMENT="lab"
SKIP_UPDATE=false
HOMELAB_VERSION="0.0.9"

while true; do
    case "$1" in
        "-e"|"--env")
            ENVIRONMENT="$2"
            shift 2
            continue
        ;;
        "--skip-update")
            SKIP_UPDATE=true
            shift 1
            continue
        ;;
        "--version")
            HOMELAB_VERSION="$2"
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

## 0. Install homelab files
if [ ! -f "homelab_v${HOMELAB_VERSION}.tar.gz" ]; then
    HOMELAB_URL="https://github.com/mpoegel/homelab/releases/latest/download/homelab_v${HOMELAB_VERSION}.tar.gz"
    if ! wget "${HOMELAB_URL}"; then
        echo "unable to download homelab release"
        exit 1
    fi
fi
tar xzf "homelab_v${HOMELAB_VERSION}.tar.gz" -C /
rm "homelab_v${HOMELAB_VERSION}.tar.gz"

. /usr/local/bin/homelab_functions.sh

## 1. Install environment
if [[ $SKIP_UPDATE == false ]]; then
    if [ "lab" == "$ENVIRONMENT" ]; then
        log_info "installing lab environment"
        /usr/local/sbin/setup_ubuntu.sh "$args"
    elif [ "edge" == "$ENVIRONMENT" ]; then
        log_info "installing edge environment"
        /usr/local/sbin/setup_envoy.sh "$args"
    else
        log_error "invalid environment: ${ENVIRONMENT}"
    fi
fi

log_info "install complete"
