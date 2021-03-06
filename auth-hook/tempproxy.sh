#!/bin/sh
# Source this file to automatically setup and teardown an HTTP* proxy
# Use the PROXY_PORT and PROXY_DEST environment variables to customize the proxy
set -x

PROXY_PORT="${AUTH_HOOK_PROXY_PORT:-1080}"
PROXY_DEST="${AUTH_HOOK_PROXY_DEST}"
DEFAULT_SSH_ID="./config/id_ed25518.tempproxy"
SSH_ID="${AUTH_HOOK_SSH_ID:-$DEFAULT_SSH_ID}"
SSH_PORT=${AUTH_HOOK_SSH_PORT:-22}
PID="$$"

# Teardown the SSH connection when the script exits
trap 'ssh -i "${SSH_ID}" -p "${SSH_PORT}" -o StrictHostKeyChecking=no -q -S ".ctrl-socket-$PID" -O exit "$PROXY_DEST"' EXIT

# Set up an SSH tunnel and wait for the port to be forwarded before continuing
if ! ssh -i "${SSH_ID}" -p "${SSH_PORT}" -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -M -S ".ctrl-socket-$PID" -f -N -D "$PROXY_PORT" "$PROXY_DEST"; then
    echo "Failed to open SSH tunnel, exiting"
    exit 1
fi

# Set environment variables to redirect HTTP* traffic through the proxy
export HTTP_PROXY="socks5://127.0.0.1:$PROXY_PORT"
export HTTPS_PROXY="$HTTP_PROXY"
