#!/bin/sh
# Source this file to automatically setup and teardown an HTTP* proxy
# Use the PROXY_PORT and PROXY_DEST environment variables to customize the proxy
set -x

if [ ! -x "$(which ssh)" ]; then
  apk add --no-cache openssh
fi

PROXY_PORT="${AUTH_HOOK_PROXY_PORT:-1080}"
PROXY_DEST="$AUTH_HOOK_PROXY_DEST"
SSH_ID="$AUTH_HOOK_SSH_ID"
SSH_PORT=${AUTH_HOOK_SSH_PORT:-22}
PID="$$"
CTRL_SOCKET="/tmp/ssh-ctrl-socket-$PID"

# Teardown the SSH connection when the script exits
trap 'ssh -i "$SSH_ID" -p "$SSH_PORT" -4 -o StrictHostKeyChecking=no -q -S $CTRL_SOCKET -O exit "$PROXY_DEST"' EXIT

# Set up an SSH tunnel and wait for the port to be forwarded before continuing
if ! ssh -i "$SSH_ID" -p "$SSH_PORT" -4 -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -M -S "$CTRL_SOCKET" -f -N -D "$PROXY_PORT" "$PROXY_DEST"; then
    echo "Failed to open SSH tunnel, exiting"
    exit 1
fi

# Set environment variables to redirect HTTP* traffic through the proxy
export HTTP_PROXY="socks5://127.0.0.1:$PROXY_PORT"
export HTTPS_PROXY="$HTTP_PROXY"
