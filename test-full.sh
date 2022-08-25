#!/bin/sh
set -x
. ./auth-hook/config/test-env
export CERTBOT_DOMAIN=bullfrog.sl8r.net
export CERTBOT_VALIDATION=test-script-test-value
if [ "$AUTH_HOOK_PROXY_DEST" != "" ]; then
  . auth-hook/tempproxy.sh
fi
cd auth-hook || exit 1
poetry run ./lexicon_auth.py
