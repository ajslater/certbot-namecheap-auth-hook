#!/bin/bash
# Fix as much as many linting issues as we can
set -euxo pipefail
cd auth-hook
poetry run isort --color .
poetry run black .
cd ..
prettier --write .
shellharden --replace ./*.sh ./**/*.sh
for f in .*ignore; do 
  sort --mmap --unique --output="$f" "$f"
done
