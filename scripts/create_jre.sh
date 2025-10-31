#!/usr/bin/env bash
set -euo pipefail

SRC_JDK="${1:-/opt/jdk}"
OUT_DIR="${2:-/opt/jre}"
MODULES="${MODULES:-java.base,java.logging,jdk.crypto.ec,jdk.crypto.cryptoki,jdk.management,jdk.unsupported}"

if [[ ! -x "${SRC_JDK}/bin/jlink" ]]; then
  echo "jlink not found in ${SRC_JDK}" >&2
  exit 1
fi

"${SRC_JDK}/bin/jlink" \
  --module-path "${SRC_JDK}/jmods" \
  --add-modules "${MODULES}" \
  --no-header-files \
  --no-man-pages \
  --strip-debug \
  --compress=2 \
  --output "${OUT_DIR}"
