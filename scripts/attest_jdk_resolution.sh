#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
OUTPUT="${2:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <target> [output-file]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RESOLVER="${ROOT_DIR}/scripts/resolve_jdk.sh"

if [[ ! -x "$RESOLVER" ]]; then
  echo "resolve_jdk.sh not found at $RESOLVER" >&2
  exit 1
fi

libc="glibc"
if [[ "$TARGET" == *"-musl" ]]; then
  libc="musl"
fi

case "$TARGET" in
  chainguard-*)
    type="chainguard"
    flavor="${TARGET#chainguard-}"
    ;;
  distroless-*)
    type="distroless"
    flavor="${TARGET#distroless-}"
    ;;
  ubi9-*)
    type="ubi9"
    flavor="${TARGET#ubi9-}"
    ;;
  *)
    echo "Unsupported target: $TARGET" >&2
    exit 1
    ;;
 esac

flavor="${flavor%-musl}"

case "$flavor" in
  jre25) flavor="jdk25" ;;
  jre26ea) flavor="jdk26ea" ;;
  jre26valhalla) flavor="jdk26valhalla" ;;
esac

entries='[]'
for arch in amd64 arm64; do
  env_output="$($RESOLVER --flavor=${flavor} --arch=${arch} --libc=${libc} --type=${type})"
  eval "$env_output"
  export ARCH LIBC FLAVOR VERSION JDK_URL JDK_SHA256 SIGNATURE_URL TYPE
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  entries=$(ENTRIES="$entries" TIMESTAMP="$timestamp" python3 <<'PY'
import json, os
entries = json.loads(os.environ['ENTRIES'])
entries.append({
  "arch": os.environ["ARCH"],
  "libc": os.environ["LIBC"],
  "flavor": os.environ["FLAVOR"],
  "version": os.environ.get("VERSION", ""),
  "jdk_url": os.environ.get("JDK_URL", ""),
  "jdk_sha256": os.environ.get("JDK_SHA256", ""),
  "signature_url": os.environ.get("SIGNATURE_URL", ""),
  "download_timestamp": os.environ["TIMESTAMP"],
})
print(json.dumps(entries))
PY
  )
done

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
payload=$(TARGET="$TARGET" TYPE="$type" FLAVOR="$flavor" LIBC="$libc" GENERATED_AT="$generated_at" ENTRIES="$entries" python3 <<'PY'
import json, os
payload = {
  "target": os.environ["TARGET"],
  "type": os.environ["TYPE"],
  "flavor": os.environ["FLAVOR"],
  "libc": os.environ["LIBC"],
  "generated_at": os.environ["GENERATED_AT"],
  "entries": json.loads(os.environ["ENTRIES"]),
}
print(json.dumps(payload, indent=2))
PY
)

if [[ -n "$OUTPUT" ]]; then
  printf '%s\n' "$payload" > "$OUTPUT"
else
  printf '%s\n' "$payload"
fi
