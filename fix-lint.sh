#!/bin/bash
# Fix as much as many linting issues as we can
set -euxo pipefail
poetry run isort .
poetry run black .
prettier --write .
