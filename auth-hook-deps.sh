#!/bin/sh
cd "$(dirname "$0")" || exit
pip3 install -U pip poetry
poetry install --no-dev
