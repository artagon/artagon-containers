#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: verify_sha256.sh <file> <sha256>" >&2
  exit 1
fi

file="$1"
expected="$2"

echo "${expected}  ${file}" | sha256sum --check --status
echo "SHA256 verified for ${file}"
