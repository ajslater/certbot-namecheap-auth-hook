#!/bin/bash
# Lint checks
set -euxo pipefail
poetry run flake8 .
poetry run black --check .
poetry run isort --check-only .
poetry run pyright
poetry run bandit -r -c "pyproject.toml" --confidence-level=medium --severity-level=medium .
poetry run vulture .
poetry run eradicate --recursive .
if [ "$(uname)" = "Darwin" ]; then
  poetry run radon mi --min B .
fi
