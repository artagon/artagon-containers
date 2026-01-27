#!/usr/bin/env bash
# refresh-versions.sh - Detect and update base image digests and package versions
#
# Usage:
#   ./scripts/refresh-versions.sh --check    # Check if updates are available (exit 1 if updates found)
#   ./scripts/refresh-versions.sh --apply    # Apply updates to lock files
#   ./scripts/refresh-versions.sh --diff     # Show differences without applying
#
# Requirements: docker, jq, curl

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSIONS_DIR="${REPO_ROOT}/versions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Get latest digest for an image
get_latest_digest() {
  local image="$1"
  docker buildx imagetools inspect "${image}" --format '{{json .Manifest.Digest}}' 2>/dev/null | tr -d '"'
}

# Get package versions from Wolfi image
get_wolfi_packages() {
  local digest="$1"
  local image="cgr.dev/chainguard/wolfi-base@${digest}"

  docker run --rm "${image}" sh -c "apk list --installed 2>/dev/null" | \
    awk -F' ' '{gsub(/-[0-9].*/, "", $1); print $1}' | sort -u
}

# Get specific package version from Wolfi
get_wolfi_package_version() {
  local digest="$1"
  local package="$2"
  local image="cgr.dev/chainguard/wolfi-base@${digest}"

  docker run --rm "${image}" sh -c "apk list --installed 2>/dev/null | grep '^${package}-[0-9]'" | \
    awk '{print $1}' | sed "s/^${package}-//"
}

# Get specific package version from Alpine
get_alpine_package_version() {
  local digest="$1"
  local package="$2"
  local image="alpine:3.20@${digest}"

  docker run --rm "${image}" sh -c "apk info -v ${package} 2>/dev/null" | \
    head -1 | sed "s/^${package}-//"
}

# Update Wolfi lock file
update_wolfi_lock() {
  local lock_file="${VERSIONS_DIR}/wolfi.lock"
  local current_digest latest_digest

  current_digest=$(jq -r '.digest' "${lock_file}")
  latest_digest=$(get_latest_digest "cgr.dev/chainguard/wolfi-base:latest")

  if [[ -z "${latest_digest}" ]]; then
    log_error "Failed to get latest Wolfi digest"
    return 1
  fi

  if [[ "${current_digest}" == "${latest_digest}" ]]; then
    log_info "Wolfi: No digest change"
    return 0
  fi

  log_info "Wolfi: Digest changed ${current_digest:0:20}... -> ${latest_digest:0:20}..."

  # Get package versions
  local packages
  packages=$(jq -r '.packages | keys[]' "${lock_file}")

  local tmp_file
  tmp_file=$(mktemp)
  jq --arg digest "${latest_digest}" \
     --arg updated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.digest = $digest | .updated = $updated' "${lock_file}" > "${tmp_file}"

  for pkg in ${packages}; do
    local version
    version=$(get_wolfi_package_version "${latest_digest}" "${pkg}" 2>/dev/null || echo "")
    if [[ -n "${version}" ]]; then
      jq --arg pkg "${pkg}" --arg ver "${version}" \
         '.packages[$pkg] = $ver' "${tmp_file}" > "${tmp_file}.new"
      mv "${tmp_file}.new" "${tmp_file}"
      log_info "  ${pkg}: ${version}"
    fi
  done

  mv "${tmp_file}" "${lock_file}"
  return 2  # Indicates changes were made
}

# Update Alpine lock file
update_alpine_lock() {
  local lock_file="${VERSIONS_DIR}/alpine.lock"
  local current_digest latest_digest

  current_digest=$(jq -r '.digest' "${lock_file}")
  latest_digest=$(get_latest_digest "alpine:3.20")

  if [[ -z "${latest_digest}" ]]; then
    log_error "Failed to get latest Alpine digest"
    return 1
  fi

  if [[ "${current_digest}" == "${latest_digest}" ]]; then
    log_info "Alpine: No digest change"
    return 0
  fi

  log_info "Alpine: Digest changed ${current_digest:0:20}... -> ${latest_digest:0:20}..."

  local packages
  packages=$(jq -r '.packages | keys[]' "${lock_file}")

  local tmp_file
  tmp_file=$(mktemp)
  jq --arg digest "${latest_digest}" \
     --arg updated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.digest = $digest | .updated = $updated' "${lock_file}" > "${tmp_file}"

  for pkg in ${packages}; do
    local version
    version=$(get_alpine_package_version "${latest_digest}" "${pkg}" 2>/dev/null || echo "")
    if [[ -n "${version}" ]]; then
      jq --arg pkg "${pkg}" --arg ver "${version}" \
         '.packages[$pkg] = $ver' "${tmp_file}" > "${tmp_file}.new"
      mv "${tmp_file}.new" "${tmp_file}"
      log_info "  ${pkg}: ${version}"
    fi
  done

  mv "${tmp_file}" "${lock_file}"
  return 2
}

# Update UBI9 lock file
update_ubi9_lock() {
  local lock_file="${VERSIONS_DIR}/ubi9.lock"
  local current_digest latest_digest
  local current_minimal_digest latest_minimal_digest
  local changes=0

  current_digest=$(jq -r '.digest' "${lock_file}")
  latest_digest=$(get_latest_digest "registry.access.redhat.com/ubi9/ubi:latest")

  current_minimal_digest=$(jq -r '.minimal.digest' "${lock_file}")
  latest_minimal_digest=$(get_latest_digest "registry.access.redhat.com/ubi9-minimal:latest")

  if [[ -z "${latest_digest}" ]] || [[ -z "${latest_minimal_digest}" ]]; then
    log_error "Failed to get latest UBI9 digests"
    return 1
  fi

  local tmp_file
  tmp_file=$(mktemp)
  cp "${lock_file}" "${tmp_file}"

  if [[ "${current_digest}" != "${latest_digest}" ]]; then
    log_info "UBI9: Digest changed ${current_digest:0:20}... -> ${latest_digest:0:20}..."
    jq --arg digest "${latest_digest}" '.digest = $digest' "${tmp_file}" > "${tmp_file}.new"
    mv "${tmp_file}.new" "${tmp_file}"
    changes=1
  else
    log_info "UBI9: No digest change"
  fi

  if [[ "${current_minimal_digest}" != "${latest_minimal_digest}" ]]; then
    log_info "UBI9-minimal: Digest changed ${current_minimal_digest:0:20}... -> ${latest_minimal_digest:0:20}..."
    jq --arg digest "${latest_minimal_digest}" '.minimal.digest = $digest' "${tmp_file}" > "${tmp_file}.new"
    mv "${tmp_file}.new" "${tmp_file}"
    changes=1
  else
    log_info "UBI9-minimal: No digest change"
  fi

  if [[ ${changes} -eq 1 ]]; then
    jq --arg updated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.updated = $updated' "${tmp_file}" > "${tmp_file}.new"
    mv "${tmp_file}.new" "${lock_file}"
    return 2
  fi

  rm -f "${tmp_file}"
  return 0
}

# Update Distroless lock file
update_distroless_lock() {
  local lock_file="${VERSIONS_DIR}/distroless.lock"
  local current_digest latest_digest

  current_digest=$(jq -r '.digest' "${lock_file}")
  latest_digest=$(get_latest_digest "gcr.io/distroless/base-debian12:latest")

  if [[ -z "${latest_digest}" ]]; then
    log_error "Failed to get latest Distroless digest"
    return 1
  fi

  if [[ "${current_digest}" == "${latest_digest}" ]]; then
    log_info "Distroless: No digest change"
    return 0
  fi

  log_info "Distroless: Digest changed ${current_digest:0:20}... -> ${latest_digest:0:20}..."

  jq --arg digest "${latest_digest}" \
     --arg updated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.digest = $digest | .updated = $updated' "${lock_file}" > "${lock_file}.tmp"
  mv "${lock_file}.tmp" "${lock_file}"
  return 2
}

# Check mode - just report if updates available
check_updates() {
  log_info "Checking for base image updates..."
  local has_updates=0

  for lock_file in "${VERSIONS_DIR}"/*.lock; do
    local name
    name=$(basename "${lock_file}" .lock)
    local registry digest latest_digest

    registry=$(jq -r '.registry' "${lock_file}")
    digest=$(jq -r '.digest' "${lock_file}")

    # Determine the full image reference
    local image_ref
    case "${name}" in
      wolfi)   image_ref="cgr.dev/chainguard/wolfi-base:latest" ;;
      alpine)  image_ref="alpine:3.20" ;;
      ubi9)    image_ref="registry.access.redhat.com/ubi9/ubi:latest" ;;
      distroless) image_ref="gcr.io/distroless/base-debian12:latest" ;;
      *)       continue ;;
    esac

    latest_digest=$(get_latest_digest "${image_ref}" 2>/dev/null || echo "")

    if [[ -z "${latest_digest}" ]]; then
      log_warn "${name}: Could not fetch latest digest"
      continue
    fi

    if [[ "${digest}" != "${latest_digest}" ]]; then
      log_warn "${name}: Update available"
      log_info "  Current: ${digest:0:20}..."
      log_info "  Latest:  ${latest_digest:0:20}..."
      has_updates=1
    else
      log_info "${name}: Up to date"
    fi
  done

  if [[ ${has_updates} -eq 1 ]]; then
    log_warn "Updates are available. Run with --apply to update lock files."
    return 1
  fi

  log_info "All lock files are up to date."
  return 0
}

# Apply updates to lock files
apply_updates() {
  log_info "Applying base image updates..."
  local total_changes=0

  update_wolfi_lock || { [[ $? -eq 2 ]] && ((total_changes++)); }
  update_alpine_lock || { [[ $? -eq 2 ]] && ((total_changes++)); }
  update_ubi9_lock || { [[ $? -eq 2 ]] && ((total_changes++)); }
  update_distroless_lock || { [[ $? -eq 2 ]] && ((total_changes++)); }

  if [[ ${total_changes} -gt 0 ]]; then
    log_info "Updated ${total_changes} lock file(s)"
    return 0
  fi

  log_info "No updates applied"
  return 0
}

# Show diff without applying
show_diff() {
  log_info "Checking differences (dry-run)..."
  check_updates
}

# Main
main() {
  local mode="${1:-}"

  case "${mode}" in
    --check)
      check_updates
      ;;
    --apply)
      apply_updates
      ;;
    --diff)
      show_diff
      ;;
    *)
      echo "Usage: $0 {--check|--apply|--diff}"
      echo ""
      echo "Options:"
      echo "  --check   Check if updates are available (exit 1 if updates found)"
      echo "  --apply   Apply updates to lock files"
      echo "  --diff    Show differences without applying"
      exit 1
      ;;
  esac
}

main "$@"
