#!/bin/sh
cd "$(dirname "$0")" || exit
apk add --no-cache \
  cargo \
  gcc \
  libffi-dev \
  musl-dev \
  openssh \
  openssl-dev \
  python3-dev
pip3 install -U pip
pip3 install --no-cache-dir -U poetry
poetry install --no-dev
