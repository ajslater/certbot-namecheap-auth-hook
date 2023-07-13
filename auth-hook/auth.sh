#!/bin/sh
# optionally run an ssh proxy and then do letsencrypt namecheap dns auth
set -x
cd "$(dirname "$0")" || exit
echo "CERTBOT_DOMAIN=$CERTBOT_DOMAIN"
echo "CERTBOT_VALIDATION=$CERTBOT_VALIDATION"
if [ "$CERTBOT_DOMAIN" = "" ] || [ "$CERTBOT_VALIDATION" = "" ]; then
  echo "Not enough certbot environment variables set"
  exit 1
fi
echo "AUTH_HOOK_PROXY_DEST=$AUTH_HOOK_PROXY_DEST"
if [ "$AUTH_HOOK_PROXY_DEST" != "" ]; then
  # shellcheck source=./auth-hook/tempproxy.sh
  . ./tempproxy.sh
fi
./letsencrypt-namecheap-dns-auth.sh
