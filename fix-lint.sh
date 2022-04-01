#!/bin/bash
# Fix as much as many linting issues as we can
set -euxo pipefail
poetry run isort .
poetry run black .
prettier --write .
for f in .*ignore; do 
  sort --mmap --unique --output="$f" "$f"
done
