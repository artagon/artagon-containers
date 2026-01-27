# Automated Digest Refresh Workflow with Package Lock Files

## Why

Base image updates currently require manual coordination between digest pins and package version pins. When base images are updated, package versions change, causing build failures if Dockerfiles have hardcoded version pins. The recent PR #43 demonstrated this issue: updating Wolfi/Alpine/Distroless/UBI9 digests broke builds because glibc, bind-tools, and other packages had newer versions.

A lock file approach (similar to npm/cargo) provides:
- **Reproducibility**: Exact package versions are recorded and auditable
- **Atomicity**: Digests and package versions update together
- **Automation**: Weekly scheduled refresh with automatic PR creation
- **Auditability**: Git history shows exactly what changed and when

## What Changes

This proposal introduces an automated digest-refresh workflow with package version lock files:

- **Lock file structure**: Create `versions/*.lock` files for each base image family (Wolfi, Alpine, UBI9, Distroless) containing digest and package versions
- **Version detection script**: Create `scripts/refresh-versions.sh` that queries container images for available package versions
- **Bake integration**: Modify `docker-bake.hcl` to read versions from lock files via variable injection
- **GitHub Actions workflow**: Create `.github/workflows/digest-refresh.yml` with weekly schedule and manual dispatch
- **Dockerfile updates**: Convert hardcoded versions to ARG references populated from lock files

**No breaking changes** - builds continue to work; lock files are additive.

## Impact

**Affected specs**:
- `digest-refresh` (NEW) - Automated base image and package version management

**Affected code**:
- Lock files: `versions/{wolfi,alpine,ubi9,distroless}.lock`
- Scripts: `scripts/refresh-versions.sh`
- Build: `docker-bake.hcl` (add variable definitions)
- Workflows: `.github/workflows/digest-refresh.yml`
- Dockerfiles: All 9 Dockerfiles (convert to ARG-based versions)

**Dependencies**:
- Docker CLI for image inspection (`docker manifest inspect`, `docker run`)
- GitHub Actions for scheduled runs and PR creation
- `jq` for JSON parsing in scripts

**Benefits**:
- Eliminates manual digest/version synchronization
- Provides full audit trail of base image changes
- Enables reproducible builds at any point in history
- Reduces security response time (automated CVE remediation via base image updates)
- PRs clearly show what packages changed and their versions

**Risks**:
- Lock file format must be stable (breaking changes require migration)
- Package queries require pulling images (CI resource usage)
- Some packages may not have stable version output formats
- Network failures during version detection need retry logic
