#!/usr/bin/env bash

set -euo pipefail

CHART_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
EXAMPLES_DIR="$CHART_DIR/examples"

if ! command -v helm >/dev/null 2>&1; then
  echo "Missing required tool: helm" >&2
  exit 1
fi

if [[ -x "$CHART_DIR/scripts/generate-docs.sh" ]]; then
  "$CHART_DIR/scripts/generate-docs.sh"
fi

helm lint "$CHART_DIR"

shopt -s nullglob
for example in "$EXAMPLES_DIR"/*.yaml; do
  echo "==> $example"
  helm lint "$CHART_DIR" -f "$example"
  helm template test "$CHART_DIR" -f "$example" >/dev/null
done
