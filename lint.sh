#!/bin/bash
# Lint checks
set -euxo pipefail
cd auth-hook
./lint.sh
cd ..
prettier --check .
hadolint ./*Dockerfile
shellharden ./*.sh ./**/*.sh
shellcheck -x ./*.sh
circleci config check .circleci/config.yml

sort --mmap --unique --check .*ignore
