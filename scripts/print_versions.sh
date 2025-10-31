#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d .env ]]; then
  echo "No .env directory. Run make resolve first." >&2
  exit 1
fi

for f in .env/*.env; do
  [[ -e "$f" ]] || continue
  echo ":: $(basename "$f")"
  grep -E '^(VERSION|JDK_URL|JDK_SHA256)' "$f"
  echo
done
