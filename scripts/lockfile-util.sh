#!/usr/bin/env bash
# lockfile-util.sh - Utilities for working with version lock files
#
# Usage:
#   ./scripts/lockfile-util.sh get <lock> <key>        # Get a value from lock file
#   ./scripts/lockfile-util.sh digest <image>          # Get digest for image type
#   ./scripts/lockfile-util.sh env                     # Output as environment variables
#   ./scripts/lockfile-util.sh bake-vars              # Output as docker-bake HCL variables
#   ./scripts/lockfile-util.sh validate               # Validate all lock files
#   ./scripts/lockfile-util.sh summary                # Show summary of all lock files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSIONS_DIR="${REPO_ROOT}/versions"

# Get a value from a lock file
get_value() {
  local lock_file="$1"
  local key="$2"

  if [[ ! -f "${VERSIONS_DIR}/${lock_file}.lock" ]]; then
    echo "Error: Lock file not found: ${lock_file}.lock" >&2
    return 1
  fi

  jq -r "${key}" "${VERSIONS_DIR}/${lock_file}.lock"
}

# Get digest for a specific image type
get_digest() {
  local image_type="$1"

  case "${image_type}" in
    wolfi)
      get_value wolfi '.digest'
      ;;
    alpine)
      get_value alpine '.digest'
      ;;
    ubi9)
      get_value ubi9 '.digest'
      ;;
    ubi9-minimal)
      get_value ubi9 '.minimal.digest'
      ;;
    distroless)
      get_value distroless '.digest'
      ;;
    *)
      echo "Error: Unknown image type: ${image_type}" >&2
      echo "Valid types: wolfi, alpine, ubi9, ubi9-minimal, distroless" >&2
      return 1
      ;;
  esac
}

# Output as environment variables (for CI)
output_env() {
  echo "# Generated from version lock files"
  echo "# Source this file or use: eval \$(./scripts/lockfile-util.sh env)"
  echo ""
  echo "export WOLFI_DIGEST=\"$(get_value wolfi '.digest')\""
  echo "export ALPINE_DIGEST=\"$(get_value alpine '.digest')\""
  echo "export UBI9_DIGEST=\"$(get_value ubi9 '.digest')\""
  echo "export UBI9_MINIMAL_DIGEST=\"$(get_value ubi9 '.minimal.digest')\""
  echo "export DISTROLESS_DIGEST=\"$(get_value distroless '.digest')\""
}

# Output as docker-bake HCL variables
output_bake_vars() {
  cat <<EOF
// Auto-generated from version lock files
// Do not edit manually - run: ./scripts/refresh-versions.sh --apply

variable "WOLFI_DIGEST" {
  default = "$(get_value wolfi '.digest')"
}

variable "ALPINE_DIGEST" {
  default = "$(get_value alpine '.digest')"
}

variable "UBI9_DIGEST" {
  default = "$(get_value ubi9 '.digest')"
}

variable "UBI9_MINIMAL_DIGEST" {
  default = "$(get_value ubi9 '.minimal.digest')"
}

variable "DISTROLESS_DIGEST" {
  default = "$(get_value distroless '.digest')"
}
EOF
}

# Validate all lock files
validate_locks() {
  local errors=0

  echo "Validating lock files..."
  echo ""

  for lock_file in "${VERSIONS_DIR}"/*.lock; do
    local name
    name=$(basename "${lock_file}" .lock)

    # Check JSON validity
    if ! jq empty "${lock_file}" 2>/dev/null; then
      echo "❌ ${name}.lock: Invalid JSON"
      ((errors++))
      continue
    fi

    # Check required fields
    local digest
    digest=$(jq -r '.digest // empty' "${lock_file}")
    if [[ -z "${digest}" ]]; then
      echo "❌ ${name}.lock: Missing 'digest' field"
      ((errors++))
      continue
    fi

    # Check digest format
    if [[ ! "${digest}" =~ ^sha256:[a-f0-9]{64}$ ]]; then
      echo "❌ ${name}.lock: Invalid digest format: ${digest}"
      ((errors++))
      continue
    fi

    local registry
    registry=$(jq -r '.registry // empty' "${lock_file}")
    if [[ -z "${registry}" ]]; then
      echo "❌ ${name}.lock: Missing 'registry' field"
      ((errors++))
      continue
    fi

    local updated
    updated=$(jq -r '.updated // empty' "${lock_file}")
    if [[ -z "${updated}" ]]; then
      echo "⚠️  ${name}.lock: Missing 'updated' timestamp"
    fi

    echo "✅ ${name}.lock: Valid"
  done

  echo ""
  if [[ ${errors} -gt 0 ]]; then
    echo "Validation failed with ${errors} error(s)"
    return 1
  fi

  echo "All lock files are valid"
  return 0
}

# Show summary of all lock files
show_summary() {
  echo "╔════════════════════════════════════════════════════════════════════════════╗"
  echo "║                           Version Lock Files Summary                        ║"
  echo "╠════════════════════════════════════════════════════════════════════════════╣"

  for lock_file in "${VERSIONS_DIR}"/*.lock; do
    local name registry digest updated
    name=$(basename "${lock_file}" .lock)
    registry=$(jq -r '.registry' "${lock_file}")
    digest=$(jq -r '.digest' "${lock_file}")
    updated=$(jq -r '.updated // "unknown"' "${lock_file}")

    printf "║ %-12s %-50s ║\n" "${name}:" "${registry}"
    printf "║   Digest:   %-60s ║\n" "${digest:0:50}..."
    printf "║   Updated:  %-60s ║\n" "${updated}"

    # Show minimal digest for UBI9
    if [[ "${name}" == "ubi9" ]]; then
      local minimal_digest
      minimal_digest=$(jq -r '.minimal.digest // empty' "${lock_file}")
      if [[ -n "${minimal_digest}" ]]; then
        printf "║   Minimal:  %-60s ║\n" "${minimal_digest:0:50}..."
      fi
    fi

    echo "╠════════════════════════════════════════════════════════════════════════════╣"
  done

  echo "╚════════════════════════════════════════════════════════════════════════════╝"
}

# Generate PR description for version updates
generate_pr_body() {
  local old_branch="${1:-main}"

  echo "## Base Image Updates"
  echo ""
  echo "This PR updates base image digests to their latest versions."
  echo ""
  echo "| Image | Registry | New Digest |"
  echo "|-------|----------|------------|"

  for lock_file in "${VERSIONS_DIR}"/*.lock; do
    local name registry digest
    name=$(basename "${lock_file}" .lock)
    registry=$(jq -r '.registry' "${lock_file}")
    digest=$(jq -r '.digest' "${lock_file}")

    echo "| ${name} | ${registry} | \`${digest:0:20}...\` |"
  done

  echo ""
  echo "---"
  echo ""
  echo "Generated by: \`./scripts/refresh-versions.sh --apply\`"
}

# Main
main() {
  local cmd="${1:-}"
  shift || true

  case "${cmd}" in
    get)
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 get <lock> <key>" >&2
        echo "Example: $0 get wolfi .digest" >&2
        return 1
      fi
      get_value "$1" "$2"
      ;;
    digest)
      if [[ $# -lt 1 ]]; then
        echo "Usage: $0 digest <image-type>" >&2
        echo "Types: wolfi, alpine, ubi9, ubi9-minimal, distroless" >&2
        return 1
      fi
      get_digest "$1"
      ;;
    env)
      output_env
      ;;
    bake-vars)
      output_bake_vars
      ;;
    validate)
      validate_locks
      ;;
    summary)
      show_summary
      ;;
    pr-body)
      generate_pr_body "${1:-main}"
      ;;
    *)
      echo "lockfile-util.sh - Utilities for version lock files"
      echo ""
      echo "Usage: $0 <command> [args]"
      echo ""
      echo "Commands:"
      echo "  get <lock> <key>    Get a value from lock file (e.g., get wolfi .digest)"
      echo "  digest <type>       Get digest for image type (wolfi, alpine, ubi9, ubi9-minimal, distroless)"
      echo "  env                 Output as environment variables"
      echo "  bake-vars           Output as docker-bake HCL variables"
      echo "  validate            Validate all lock files"
      echo "  summary             Show summary of all lock files"
      echo "  pr-body             Generate PR description body"
      echo ""
      echo "Examples:"
      echo "  $0 digest wolfi"
      echo "  eval \$($0 env)"
      echo "  $0 bake-vars > versions.hcl"
      return 1
      ;;
  esac
}

main "$@"
