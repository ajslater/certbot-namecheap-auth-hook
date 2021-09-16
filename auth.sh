#!/bin/sh
set -x
cd "$(dirname "$0")" || exit
echo "CERTBOT_DOMAIN=$CERTBOT_DOMAIN"
echo "CERTBOT_VALIDATION=$CERTBOT_VALIDATION"
if [ -z "$CERTBOT_DOMAIN" ] || [ -z "$CERTBOT_VALIDATION" ]; then
  echo "Not enough certbot environment variables set"
  exit 1
fi
if [ -n "$AUTH_HOOK_PROXY_DEST" ]; then
  . ./tempproxy.sh
fi
poetry run ./lexicon_auth.py
