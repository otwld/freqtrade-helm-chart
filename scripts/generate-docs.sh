#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELM_DOCS_VERSION="${HELM_DOCS_VERSION:-1.14.2}"

if command -v helm-docs >/dev/null 2>&1; then
  (
    cd "$ROOT_DIR"
    helm-docs
  )
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  docker run --rm \
    --volume "$ROOT_DIR:/helm-docs" \
    --user "$(id -u):$(id -g)" \
    "jnorwood/helm-docs:v${HELM_DOCS_VERSION}"
  exit 0
fi

echo "Missing required tool: helm-docs or docker" >&2
exit 1
