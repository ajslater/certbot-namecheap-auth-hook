#!/bin/sh
set -x
. ./.env.test
if [ "$AUTH_HOOK_PROXY_DEST" != "" ]; then
    . auth-hook/tempproxy.sh
fi
cd auth-hook || exit 1
./letsencrypt-namecheap-dsn-auth.sh
