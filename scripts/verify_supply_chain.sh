#!/usr/bin/env bash
set -euo pipefail

IMAGE_REF="${1:-}"
if [[ -z "$IMAGE_REF" ]]; then
  echo "Usage: $0 <image-ref>" >&2
  exit 1
fi

if ! command -v cosign >/dev/null 2>&1; then
  echo "cosign is required to verify signatures and attestations" >&2
  exit 1
fi

export COSIGN_EXPERIMENTAL=1

cosign verify "$IMAGE_REF" >/dev/null
cosign verify-attestation --type slsaprovenance "$IMAGE_REF" >/dev/null
cosign verify-attestation --type cyclonedx "$IMAGE_REF" >/dev/null
cosign verify-attestation --type https://artagon.dev/attestations/jdk-resolution/v1 "$IMAGE_REF" >/dev/null
cosign verify-attestation --type https://artagon.dev/attestations/sbom-metadata/v1 "$IMAGE_REF" >/dev/null
cosign verify-attestation --type https://artagon.dev/attestations/vulnerability-scan/v1 "$IMAGE_REF" >/dev/null

echo "Supply-chain verification succeeded for ${IMAGE_REF}"
