#!/bin/bash
# Build multi-arrch test and load because bake sucks
# https://github.com/docker/roadmap/issues/37
set -euo pipefail
docker buildx build --output=type=oci . | docker load
