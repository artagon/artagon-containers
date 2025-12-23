#!/usr/bin/env bash
set -euo pipefail

IMAGE_REF="${1:-}"
if [[ -z "$IMAGE_REF" ]]; then
  echo "Usage: $0 <image-ref>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SECCOMP_PROFILE="${SECCOMP_PROFILE:-${ROOT_DIR}/security/seccomp-java.json}"
APPARMOR_PROFILE="${APPARMOR_PROFILE:-${ROOT_DIR}/security/apparmor-java.txt}"
APPARMOR_PROFILE_NAME="${APPARMOR_PROFILE_NAME:-artagon-java}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to run hardening validation" >&2
  exit 1
fi

ensure_image_present() {
  if ! docker image inspect "$IMAGE_REF" >/dev/null 2>&1; then
    echo "Image not present locally, pulling ${IMAGE_REF}..."
    docker pull "$IMAGE_REF" >/dev/null
  fi
}

require_label() {
  local key="$1"
  local value
  value=$(docker image inspect "$IMAGE_REF" --format "{{ index .Config.Labels \"$key\" }}" 2>/dev/null || true)
  if [[ -z "$value" || "$value" == "<no value>" ]]; then
    echo "Missing OCI label: $key" >&2
    exit 1
  fi
}

require_label_value() {
  local key="$1"
  local expected="$2"
  local value
  value=$(docker image inspect "$IMAGE_REF" --format "{{ index .Config.Labels \"$key\" }}" 2>/dev/null || true)
  if [[ "$value" != "$expected" ]]; then
    echo "Label $key expected \"$expected\", got \"${value:-<empty>}\"" >&2
    exit 1
  fi
}

check_user() {
  local user
  user=$(docker image inspect "$IMAGE_REF" --format "{{ .Config.User }}" 2>/dev/null || true)
  if [[ "$user" != "65532" && "$user" != "65532:65532" ]]; then
    echo "Expected non-root user 65532:65532, found: ${user:-<empty>}" >&2
    exit 1
  fi
}

check_healthcheck() {
  local health
  health=$(docker image inspect "$IMAGE_REF" --format "{{ if .Config.Healthcheck }}present{{ end }}" 2>/dev/null || true)
  if [[ "$health" != "present" ]]; then
    echo "Missing HEALTHCHECK in image metadata" >&2
    exit 1
  fi
}

load_apparmor_profile() {
  if [[ "${SKIP_APPARMOR:-}" == "1" ]]; then
    return 0
  fi

  if [[ ! -d /sys/kernel/security/apparmor ]]; then
    echo "AppArmor is not enabled on this host. Set SKIP_APPARMOR=1 to skip." >&2
    exit 1
  fi

  if ! command -v apparmor_parser >/dev/null 2>&1; then
    echo "apparmor_parser not found. Install apparmor-utils or set SKIP_APPARMOR=1." >&2
    exit 1
  fi

  if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      echo "sudo is required to load AppArmor profile. Set SKIP_APPARMOR=1 to skip." >&2
      exit 1
    fi
    sudo apparmor_parser -r "$APPARMOR_PROFILE"
  else
    apparmor_parser -r "$APPARMOR_PROFILE"
  fi
}

run_check() {
  local name="$1"
  shift
  echo "Running hardening check: ${name}"
  docker run --rm \
    --read-only \
    --tmpfs /tmp:rw,exec,nosuid,nodev \
    --cap-drop=ALL \
    --security-opt no-new-privileges:true \
    "$@" \
    "$IMAGE_REF" -XshowSettings:properties -version >/dev/null
}

ensure_image_present

require_label "org.opencontainers.image.security.capabilities"
require_label "org.opencontainers.image.security.readonly-rootfs"
require_label "org.opencontainers.image.security.seccomp"
require_label_value "org.opencontainers.image.security.capabilities" "NONE"
require_label_value "org.opencontainers.image.security.readonly-rootfs" "recommended"
require_label_value "org.opencontainers.image.security.seccomp" "security/seccomp-java.json"
check_user
check_healthcheck

if [[ ! -f "$SECCOMP_PROFILE" ]]; then
  echo "Seccomp profile not found at $SECCOMP_PROFILE" >&2
  exit 1
fi

load_apparmor_profile

run_check "baseline"

if [[ "${SKIP_SECCOMP:-}" != "1" ]]; then
  run_check "seccomp" --security-opt "seccomp=${SECCOMP_PROFILE}"
fi

if [[ "${SKIP_APPARMOR:-}" != "1" ]]; then
  run_check "apparmor" --security-opt "apparmor=${APPARMOR_PROFILE_NAME}"
fi

echo "Hardening validation completed for ${IMAGE_REF}"
