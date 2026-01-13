#!/bin/bash
set -u

. bin/homelab_functions.sh || . /usr/local/bin/homelab_functions.sh

TEMP=$(getopt -o "u:h:a:" --long "user:,host:,archive:" -n "do_release.sh" -- "$@")
eval set -- "$TEMP"
unset TEMP

REMOTE_USER="root"
REMOTE_HOST=""
ARCHIVE_FILE=""
REMOTE_TMP_DIR="/tmp/homelab"

while true; do
    case "$1" in
        "-u"|"--user")
            REMOTE_USER="$2"
            shift 2
            continue
        ;;
        "-h"|"--host")
            REMOTE_HOST="$2"
            shift 2
            continue
        ;;
        "-a"|"--archive")
            ARCHIVE_FILE="$2"
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

homl_get() {
    local file="$1"
    local target_section="$2"

    [[ -f "$file" ]] || return 1
    [[ -n "$target_section" ]] || return 1

    local section=""
    local in_section=0

    while IFS= read -r line; do
        # Preserve original line, but create a trimmed copy for parsing
        local raw="$line"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Skip empty lines and full-line comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Section header [[section]]
        if [[ "$line" =~ ^\[\[(.+)\]\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            in_section=0
            [[ "$section" == "$target_section" ]] && in_section=1
            continue
        fi

        # Emit lines only if currently in target section
        if (( in_section )); then
            printf '%s\n' "$raw"
        fi
    done < "$file"

    return 0
}

# ----------------------------
# Preconditions
# ----------------------------
[[ ! -z "$REMOTE_HOST" ]] || log_error "remote host is required"
[[ ! -z "$ARCHIVE_FILE" ]] || log_error "package file is required"
[[ -f "$ARCHIVE_FILE" ]] || log_error "package file not found"
[[ -f ".manifest" ]] || log_error ".manifest not found"

command -v scp >/dev/null 2>&1 || log_error "scp not found"
command -v ssh >/dev/null 2>&1 || log_error "ssh not found"

# ----------------------------
# Run pre-install commands
# ----------------------------
PRE_INSTALL_CMDS="$(homl_get ".manifest" "pre_install")"
if [[ ! -z "$PRE_INSTALL_CMDS" ]]; then
    log_info "Running pre-install instructions"
    printf '%s\n' "$PRE_INSTALL_CMDS" | ssh "${REMOTE_USER}@${REMOTE_HOST}" bash -Eeuo pipefail -s
fi

# ----------------------------
# Create remote temp directory
# ----------------------------
log_info "Creating remote temporary directory"
ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p '$REMOTE_TMP_DIR'"
[[ $? -eq 0 ]] || log_error "Failed to create remote directory"

# ----------------------------
# Copy archive to remote host
# ----------------------------
log_info "Copying archive to remote host"
REMOTE_ARCHIVE="${REMOTE_TMP_DIR}/${ARCHIVE_FILE}"
scp "$ARCHIVE_FILE" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_ARCHIVE}"
[[ $? -eq 0 ]] || log_error "Failed to copy archive to remote host"

# ----------------------------
# Unpack archive on remote host
# ----------------------------
log_info "Unpacking archive on remote host"
ssh "${REMOTE_USER}@${REMOTE_HOST}" "
    set -e
    tar -xzf '$REMOTE_ARCHIVE' -C /
"
[[ $? -eq 0 ]] || log_error "Failed to unpack archive"

# ----------------------------
# Run post-install commands
# ----------------------------
POST_INSTALL_CMDS="$(homl_get ".manifest" "post_install")"
if [[ ! -z "$POST_INSTALL_CMDS" ]]; then
    log_info "Running post-install instructions"
    printf '%s\n' "$POST_INSTALL_CMDS" | ssh "${REMOTE_USER}@${REMOTE_HOST}" bash -Eeuo pipefail -s
fi

# ----------------------------
# Cleanup
# ----------------------------
log_info "Cleaning up remote temporary files"
ssh "${REMOTE_USER}@${REMOTE_HOST}" "rm -f '$REMOTE_ARCHIVE'"

log_info "Deployment completed successfully"
