#!/bin/sh
set -x
. ./tempproxy.sh
echo "$HTTPS_PROXY"
curl "https://ipv4.icanhazip.com"
