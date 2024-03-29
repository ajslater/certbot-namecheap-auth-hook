#!/bin/bash
# Install docker buildkit for building mulit-arch
set -euxo pipefail
source .env
export DOCKER_CLI_EXPERIMENTAL=enabled
export DOCKER_BUILDKIT=1
docker run --rm --privileged tonistiigi/binfmt:latest --install "$PLATFORMS"
