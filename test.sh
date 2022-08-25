#!/bin/sh
set -x
. auth-hook/config/test-env
. auth-hook/tempproxy.sh
cd auth-hook || exit 1
echo "$HTTPS_PROXY"
curl "https://ipv4.icanhazip.com"
