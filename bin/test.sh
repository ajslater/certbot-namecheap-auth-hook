#!/bin/sh
# Test the full auth hook works optionally with the proxy
set -x
. ./.env.test
if [ "$AUTH_HOOK_PROXY_DEST" != "" ]; then
    . auth-hook/tempproxy.sh
fi
cd auth-hook || exit 1
./letsencrypt-namecheap-dns-auth.sh
