#!/bin/sh
set -x
. .env.test
. auth-hook/tempproxy.sh
cd auth-hook || exit 1
echo "$HTTPS_PROXY"
curl "https://ipv4.icanhazip.com"
