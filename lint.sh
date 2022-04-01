#!/bin/bash
# Lint checks
set -euxo pipefail
poetry run flake8 .
poetry run isort --check-only .
poetry run black --check .
prettier --check .
hadolint ./*Dockerfile
shellcheck -x ./*.sh
sort --mmap --unique --check .*ignore
