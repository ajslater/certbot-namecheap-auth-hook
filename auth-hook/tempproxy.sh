#!/bin/sh
# Source this file to automatically setup and teardown an HTTP* proxy
# Use the PROXY_PORT and PROXY_DEST environment variables to customize the proxy
set -x

if [ ! -x "$(which ssh)" ]; then
  apk add --no-cache openssh
fi
SCRIPT_DIR="$(dirname "$0")"
PROXY_PORT="${AUTH_HOOK_PROXY_PORT:-1080}"
PROXY_DEST="$AUTH_HOOK_PROXY_DEST"
# ssh seems to treat relative paths differently.
SSH_ID=$(realpath "$AUTH_HOOK_SSH_ID")
SSH_PORT=${AUTH_HOOK_SSH_PORT:-22}
SSH_CONFIG=$(realpath "$SCRIPT_DIR"/ssh_config)
SSH_CMD="ssh -F $SSH_CONFIG -i $SSH_ID -p $SSH_PORT"
SSH_START="$SSH_CMD -D $PROXY_PORT $PROXY_DEST"
SSH_END="$SSH_CMD -q -O exit $PROXY_DEST"

# Teardown the SSH connection when the script exits
trap '$SSH_END' EXIT

# Set up an SSH tunnel and wait for the port to be forwarded before continuing
# XXX SSH_START cannot be in quotes XXX
if ! $SSH_START; then
  echo "Failed to open SSH tunnel, exiting"
  exit 1
fi

# Set environment variables to redirect HTTP* traffic through the proxy
export http_proxy="socks5://127.0.0.1:$PROXY_PORT"
export https_proxy="$http_proxy"
