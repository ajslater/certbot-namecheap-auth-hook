#!/bin/bash
# Build docker image for all platforms
set -xeuo pipefail
source .env
export DOCKER_CLI_EXPERIMENTAL=enabled
export DOCKER_BUILDKIT=1
docker buildx create --use

DOCKER_CMD=("docker" "buildx" "bake")
if [ "${1:-}" == "push" ]; then
    DOCKER_CMD=("${DOCKER_CMD[@]}" "--push")
fi
"${DOCKER_CMD[@]}"
