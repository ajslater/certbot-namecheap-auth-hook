#!/bin/sh
set -x
. ./auth-hook/config/test-env
export CERTBOT_DOMAIN=bullfrog.sl8r.net
export CERTBOT_VALIDATION=test-script-test-value
cd auth-hook || exit 1
if [ "$AUTH_HOOK_PROXY_DEST" != "" ]; then
  . ./tempproxy.sh
fi
poetry run ./lexicon_auth.py
