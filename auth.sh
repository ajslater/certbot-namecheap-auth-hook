#!/bin/sh
set -x
cd "$(dirname "$0")" || exit
if [ -n "$PROXY_DEST" ]; then
  . ./tempproxy.sh
fi
echo "CERTBOT_DOMAIN=$CERTBOT_DOMAIN"
echo "CERTBOT_VALIDATION=$CERTBOT_VALIDATION"
poetry run ./lexicon_auth.py
