#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/docs"
TARGET_DIR="${1:-}"

if [[ -z "$TARGET_DIR" ]]; then
  echo "Usage: $0 /path/to/freqtrade-helm-chart.wiki" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

cp "$SOURCE_DIR/Home.md" "$TARGET_DIR/Home.md"
cp "$SOURCE_DIR/Architecture.md" "$TARGET_DIR/Architecture.md"
cp "$SOURCE_DIR/Installation-and-Upgrades.md" "$TARGET_DIR/Installation-and-Upgrades.md"
cp "$SOURCE_DIR/Examples.md" "$TARGET_DIR/Examples.md"
cp "$SOURCE_DIR/Operations.md" "$TARGET_DIR/Operations.md"
cp "$SOURCE_DIR/Releases-and-CI.md" "$TARGET_DIR/Releases-and-CI.md"
cp "$SOURCE_DIR/Troubleshooting.md" "$TARGET_DIR/Troubleshooting.md"
cp "$SOURCE_DIR/_Sidebar.md" "$TARGET_DIR/_Sidebar.md"

echo "Exported wiki pages to $TARGET_DIR"
