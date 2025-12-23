# UBI9 Minimization Review

## Summary

This project uses `registry.access.redhat.com/ubi9-minimal` as the UBI9 runtime base. The image is digest-pinned and provides the minimum utilities required for the runtime health check and non-root user setup.

## Base Images Evaluated

- **ubi9-minimal** (current)
  - Digest: `sha256:6fc28bcb6776e387d7a35a2056d9d2b985dc4e26031e98a2bd35a7137cd6fd71`
- **ubi9-micro** (evaluation)
  - Digest: `sha256:e9765516d74cafded50d8ef593331eeca2ef6eababdda118e5297898d99b7433`

## Findings

### ubi9-minimal

The runtime relies on base-provided utilities for the health check and user setup:

- `coreutils-single`
- `shadow-utils` (provides `useradd`)
- `sed`, `grep`, `gawk`

Package inventory for the pinned digest is recorded in:
- `docs/security/ubi9-packages.txt`

### ubi9-micro

`ubi9-micro` removes the package manager and RPM tooling, which makes it difficult to:

- Install or update packages in the runtime layer
- Create non-root users via `useradd`
- Audit packages using `rpm -qa`

Because `ubi9-micro` lacks RPM tooling and user management utilities, it is not currently suitable for this project without additional build-time user provisioning or filesystem templating.

## Size Comparison (amd64)

Measured via `docker image inspect` on the pinned digests:

- **ubi9-minimal**: `108,778,110` bytes (~103.8 MB)
- **ubi9-micro**: `24,038,533` bytes (~22.9 MB)

## Decision

Continue using `ubi9-minimal` for now. Revisit `ubi9-micro` if we adopt a build-time user provisioning approach and can validate health checks without coreutils/grep/sed/gawk.

## Reproduction Commands

```bash
# Package inventory
docker run --rm registry.access.redhat.com/ubi9-minimal@sha256:6fc28bcb6776e387d7a35a2056d9d2b985dc4e26031e98a2bd35a7137cd6fd71 \
  rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort

# Size comparison
docker image inspect registry.access.redhat.com/ubi9-minimal@sha256:6fc28bcb6776e387d7a35a2056d9d2b985dc4e26031e98a2bd35a7137cd6fd71 \
  --format '{{.Size}}'

docker image inspect registry.access.redhat.com/ubi9-micro:latest \
  --format '{{.Size}}'
```
