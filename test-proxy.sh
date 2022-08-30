#!/bin/sh
set -x
. .env.test
. auth-hook/tempproxy.sh
cd auth-hook || exit 1
echo "$https_proxy"
curl "https://ipv4.icanhazip.com"
