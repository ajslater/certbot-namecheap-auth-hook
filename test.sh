#!/bin/sh
set -x
. ./config/test-env
. ./auth-hook/tempproxy.sh
echo "$HTTPS_PROXY"
curl "https://ipv4.icanhazip.com"
