#!/bin/bash
# Build docker image for all platforms
set -xeuo pipefail
source .env
export DOCKER_CLI_EXPERIMENTAL=enabled
export DOCKER_BUILDKIT=1
docker buildx create --use

if [ "${1:-}" == "push" ]; then
    BAKE_ARGS="--push"
fi
# shellcheck disable=SC2086
docker buildx bake ${BAKE_ARGS:-}
