#!/bin/sh
set -x
cd "$(dirname "$0")" || exit
echo "CERTBOT_DOMAIN=$CERTBOT_DOMAIN"
echo "CERTBOT_VALIDATION=$CERTBOT_VALIDATION"
if [ -z "$CERTBOT_DOMAIN" ] || [ -z "$CERTBOT_VALIDATION" ]; then
  echo "Not enough certbot environment variables set"
  exit 1
fi
# Would be nice to find a way for certbot parent container to 
#   only run deps once
. ./auth-hook-deps.sh
if [ -n "$AUTH_HOOK_PROXY_DEST" ]; then
  . ./tempproxy.sh
fi
poetry run ./lexicon_auth.py
