#!/bin/sh
cd "$(dirname "$0")" || exit
apk add --no-cache gcc musl-dev libffi-dev openssl-dev python3-dev openssh cargo
pip3 install -U pip
CRYPTOGRAPHY_DONT_BUILD_RUST=1 pip3 install --no-cache-dir -U poetry
poetry install --no-dev
