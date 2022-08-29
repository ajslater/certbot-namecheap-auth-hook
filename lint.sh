#!/bin/bash
# Lint checks
set -euxo pipefail
prettier --check .
hadolint ./*Dockerfile
shellharden ./*.sh ./**/*.sh
shellcheck -x ./*.sh
circleci config check .circleci/config.yml

sort --mmap --unique --check .*ignore
