# CI Images Specification

## ADDED Requirements

### Requirement: Single Architecture Build

CI images SHALL be built for linux/amd64 architecture only to optimize build speed and reduce CI costs.

#### Scenario: CI image is single architecture

- **WHEN** CI image is built and inspected
- **THEN** image manifest SHALL contain only linux/amd64 platform
- **AND** image SHALL NOT include linux/arm64 or other architectures

#### Scenario: CI build completes faster than multi-arch

- **WHEN** CI workflow builds single-arch image
- **THEN** build time SHALL be at least 40% faster than equivalent multi-arch build
- **AND** build SHALL not use QEMU emulation

#### Scenario: CI image runs on amd64 hosts

- **WHEN** CI image is deployed to linux/amd64 host
- **THEN** container SHALL start successfully
- **AND** Java application SHALL execute normally

### Requirement: Ephemeral Image Tags

CI images SHALL use ephemeral tags with `ci-` prefix that can be overwritten and are not intended for production deployment.

#### Scenario: CI image tagged with ci- prefix

- **WHEN** CI build creates image tag
- **THEN** tag SHALL match pattern `ci-<base>-<flavor>` (e.g., `ci-chainguard-jdk25`)
- **AND** tag SHALL NOT use production naming convention

#### Scenario: CI tags are unstable

- **WHEN** subsequent PR builds produce same CI tag
- **THEN** registry MAY overwrite previous image with same tag
- **AND** documentation SHALL warn users that CI tags are unstable

#### Scenario: CI image includes warning label

- **WHEN** CI image OCI metadata is inspected
- **THEN** label `org.opencontainers.image.ci` SHALL equal "true"
- **AND** label `org.opencontainers.image.description` SHALL include warning "CI image - not for production use"

### Requirement: No Cryptographic Signing

CI images SHALL NOT be signed with Cosign or include cryptographic attestations to reduce build time.

#### Scenario: CI image is not signed

- **WHEN** user attempts to verify CI image signature with Cosign
- **THEN** verification SHALL fail with "no matching signatures" error
- **AND** image SHALL be usable without signature verification

#### Scenario: CI workflow skips signing steps

- **WHEN** CI workflow builds image
- **THEN** workflow SHALL NOT invoke Cosign signing commands
- **AND** workflow SHALL NOT invoke Cosign attestation commands
- **AND** workflow SHALL complete at least 30 seconds faster due to skipped signing

### Requirement: No SBOM Generation

CI images SHALL NOT include Software Bill of Materials (SBOM) generation to optimize build performance.

#### Scenario: CI workflow skips SBOM generation

- **WHEN** CI workflow builds image
- **THEN** workflow SHALL NOT invoke Syft or SBOM generation tools
- **AND** workflow SHALL NOT attach SBOM attestations to image

#### Scenario: CI image SBOM unavailable

- **WHEN** user attempts to download SBOM from CI image
- **THEN** operation SHALL fail (no SBOM attached)
- **AND** documentation SHALL direct users to production images for SBOM access

### Requirement: Basic Vulnerability Scanning

CI images SHALL be scanned with Trivy only (not Grype) and fail builds on CRITICAL severity CVEs only.

#### Scenario: CI scan fails on CRITICAL CVE

- **WHEN** Trivy scan detects CRITICAL severity CVE in CI image
- **THEN** CI build SHALL exit with non-zero status
- **AND** CVE details SHALL be logged to build output
- **AND** build SHALL NOT proceed to subsequent steps

#### Scenario: CI scan passes on HIGH severity CVE

- **WHEN** Trivy scan detects HIGH severity CVE (but no CRITICAL)
- **THEN** CI build SHALL continue successfully
- **AND** CVE SHALL be logged for informational purposes
- **AND** main branch build will enforce stricter threshold

#### Scenario: CI scan uses single scanner

- **WHEN** CI workflow performs vulnerability scanning
- **THEN** workflow SHALL invoke Trivy only
- **AND** workflow SHALL NOT invoke Grype or additional scanners
- **AND** scan SHALL complete at least 50% faster than dual-scanner approach

### Requirement: Local Image Loading

CI images SHALL be loaded into Docker daemon using `--load` flag rather than pushed to registry to enable local testing.

#### Scenario: CI build loads image locally

- **WHEN** CI workflow builds image
- **THEN** workflow SHALL use `docker buildx bake --load`
- **AND** image SHALL be available in Docker daemon as `local:ci-<target>`
- **AND** workflow SHALL NOT push image to registry

#### Scenario: Local image available for testing

- **WHEN** CI workflow completes successfully
- **THEN** subsequent workflow steps SHALL access image via `local:ci-<target>` reference
- **AND** image SHALL be scannable by Trivy using local reference

### Requirement: GitHub Actions Cache Optimization

CI builds SHALL use GitHub Actions cache backend for BuildKit layers to maximize cache hit rate and minimize build time.

#### Scenario: CI build uses GHA cache

- **WHEN** CI workflow builds image
- **THEN** workflow SHALL specify `--set *.cache-from=type=gha`
- **AND** workflow SHALL specify `--set *.cache-to=type=gha,mode=max`
- **AND** cache scope SHALL be per-target to prevent pollution

#### Scenario: Cache hit accelerates build

- **WHEN** CI build runs with warm cache (previous build on same target)
- **THEN** build SHALL achieve at least 80% cache hit rate
- **AND** build time SHALL be at least 60% faster than cold cache build

#### Scenario: Cache storage within limits

- **WHEN** all CI targets have cached layers
- **THEN** total cache size SHALL NOT exceed GitHub Actions 10GB limit
- **AND** least recently used caches SHALL be automatically evicted if limit approached

### Requirement: Optional Debugging Tools

CI images built with BUILD_TARGET=ci SHALL include debugging tools (curl, netcat, bind-tools) to facilitate troubleshooting during development.

#### Scenario: CI build includes debugging tools

- **WHEN** image is built with `--build-arg BUILD_TARGET=ci`
- **THEN** image SHALL include debugging utilities (curl, netcat, bind-tools)
- **AND** production build with `BUILD_TARGET=production` SHALL NOT include these tools

#### Scenario: Debugging tools increase image size

- **WHEN** CI image size is compared to production image size
- **THEN** CI image SHALL be up to 50MB larger due to debugging tools
- **AND** size increase is acceptable for CI use case

#### Scenario: Debugging tools functional

- **WHEN** user executes debugging command in CI container
- **THEN** tools SHALL function correctly (e.g., `curl https://example.com`)
- **AND** tools SHALL assist in diagnosing connectivity or configuration issues

### Requirement: PR Build Trigger

CI builds SHALL trigger automatically on pull request events (open, synchronize, reopened) to provide fast feedback to contributors.

#### Scenario: CI build triggers on PR creation

- **WHEN** pull request is opened
- **THEN** CI workflow SHALL trigger automatically
- **AND** CI workflow SHALL build all image targets in matrix
- **AND** PR checks SHALL report build status

#### Scenario: CI build triggers on PR update

- **WHEN** pull request is updated with new commits
- **THEN** CI workflow SHALL trigger automatically for new commits
- **AND** previous CI workflow runs MAY be cancelled automatically
- **AND** only latest commit SHALL be built and scanned

#### Scenario: CI build does not trigger on main push

- **WHEN** commits are pushed to main branch
- **THEN** CI workflow SHALL NOT trigger
- **AND** production build workflow SHALL handle main branch builds
