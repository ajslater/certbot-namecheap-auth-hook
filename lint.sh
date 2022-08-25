#!/bin/bash
# Lint checks
set -euxo pipefail
cd auth-hook
poetry run flake8 .
poetry run black --check .
poetry run isort --color --check-only .
poetry run pyright
poetry run bandit -r -c "pyproject.toml" --confidence-level=medium --severity-level=medium .
poetry run vulture .
poetry run eradicate --recursive .
if [ "$(uname)" = "Darwin" ]; then
  poetry run radon mi --min B .
fi
cd ..
prettier --check .
hadolint ./*Dockerfile
shellharden ./*.sh ./**/*.sh
shellcheck -x ./*.sh
circleci config check .circleci/config.yml

sort --mmap --unique --check .*ignore
