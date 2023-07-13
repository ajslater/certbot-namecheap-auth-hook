#!/bin/sh
# Test the full auth hook works optionally with the proxy
set -x
. ./.env.test
if [ "$AUTH_HOOK_PROXY_DEST" != "" ]; then
    . auth-hook/tempproxy.sh
fi
cd auth-hook || exit 1
export AUTH_HOOK_CLIENT_IP
export AUTH_HOOK_NC_USER
export AUTH_HOOK_NC_API_KEY
export CERTBOT_DOMAIN
export CERTBOT_VALIDATION
./letsencrypt-namecheap-dns-auth.sh
