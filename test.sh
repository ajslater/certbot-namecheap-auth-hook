#!/bin/sh
set -x
cd auth-hook || exit 1
. ./config/test-env
. ./tempproxy.sh
echo "$HTTPS_PROXY"
curl "https://ipv4.icanhazip.com"
