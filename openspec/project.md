# Project Context

## Purpose

Artagon Containers provides hardened, production-ready OCI (Open Container Initiative) container images for JVM workloads. The project delivers multi-architecture (linux/amd64, linux/arm64) container images across three enterprise-grade base distributions:

- **Chainguard Wolfi**: Minimal musl-based images optimized for security
- **Google Distroless**: Ultra-minimal runtime-only images with glibc and musl variants
- **Red Hat UBI9 Minimal**: Enterprise-supported RHEL-based images

Each image variant ships with pre-installed Eclipse Temurin JDK builds:
- **JDK 25 GA**: Current production release
- **JDK 26 EA**: Early access preview of upcoming release
- **JDK 26 Valhalla EA**: Early access with Project Valhalla enhancements

**Key Goals**:
- Provide secure, non-root container images with minimal attack surface
- Support reproducible builds with digest pinning and SBOM attestation
- Enable supply chain verification through Cosign signing and SLSA provenance
- Maintain zero HIGH/CRITICAL CVEs through automated scanning gates
- Deliver consistent multi-architecture images for cloud-native deployments

## Tech Stack

### Core Technologies
- **Docker**: Containerization platform (v24+)
- **BuildKit/Buildx**: Multi-platform image builds with advanced caching
- **Bash**: Build orchestration and JDK resolution scripts
- **Python 3**: Metadata parsing for JDK resolution
- **HCL (HashiCorp Configuration Language)**: Docker Bake build definitions

### Security & Supply Chain Tools
- **Syft**: SBOM (Software Bill of Materials) generation in CycloneDX format
- **Trivy**: Vulnerability scanning with HIGH/CRITICAL gates
- **Grype**: Additional vulnerability assessment
- **Cosign**: Keyless image signing and attestation (Sigstore)
- **Hadolint**: Dockerfile linting
- **Dockle**: Container image security linter

### Base Images
- `cgr.dev/chainguard/wolfi-base` (digest-pinned)
- `gcr.io/distroless/base-debian12` and `static-debian12` (digest-pinned)
- `registry.access.redhat.com/ubi9-minimal` (digest-pinned)

### Distribution Sources
- **Eclipse Adoptium API**: JDK 25 GA binaries with checksums
- **Artagon Homebrew Taps**: JDK 26 EA and Valhalla builds from custom formulae

### CI/CD
- **GitHub Actions**: Automated build, test, scan, and publish workflows
- **GitHub Container Registry (GHCR)**: Image hosting at `ghcr.io/artagon/artagon-containers`
- **GitHub Packages**: Artifact storage and distribution

## Project Conventions

### Code Style

**Shell Scripts** (scripts/*.sh):
- POSIX-compliant Bash with `set -euo pipefail` safety guards
- Shellcheck-validated with no warnings
- Function-based organization with clear separation of concerns
- Comprehensive usage documentation and error messages
- Environment variable inputs with sensible defaults

**Dockerfiles** (images/*/Dockerfile.*):
- Multi-stage builds to minimize final image size
- Digest-pinned base images for reproducibility
- Non-root user execution (uid=65532, gid=65532)
- Security hardening: no-new-privileges, read-only rootfs compatibility
- OCI labels for metadata, SBOM pointers, and licenses
- Minimal layer count through command consolidation

**Build Configuration**:
- Docker Bake HCL format for declarative multi-target builds
- Platform matrix in Makefile for consistent invocation
- Build args passed through environment variable files

### Architecture Patterns

**Build System Architecture**:
```
Makefile (orchestration)
    └── docker-bake.hcl (target definitions)
        └── Dockerfiles (image builds)
            └── scripts/resolve_jdk.sh (metadata resolution)
                └── Adoptium API or Artagon taps (JDK sources)
```

**Multi-Stage Build Pattern**:
1. **Builder stage**: Alpine/Wolfi with build tools (curl, bash, python3)
2. **Resolver execution**: Dynamic JDK URL/SHA resolution based on arch/libc
3. **Download & verify**: Secure download with SHA256 validation
4. **Runtime stage**: Copy JDK artifacts to minimal base image
5. **Hardening**: Non-root user, WORKDIR, security labels

**Resolution Strategy**:
- JDK 25 GA: Query Adoptium REST API for latest release metadata
- JDK 26 EA/Valhalla: Parse Homebrew formula files from GitHub
- Architecture mapping: amd64 (x64, x86_64) / arm64 (aarch64)
- Libc fallback: musl variants fall back to glibc if musl build unavailable

**Image Tagging Scheme**:
- Pattern: `{base}-{jdk-variant}[-libc]`
- Examples: `chainguard-jdk25`, `distroless-jre26ea-musl`, `ubi9-jdk26valhalla`
- Aliases: musl variants include explicit `-musl` suffix for clarity

### Testing Strategy

**Development Environment**:
- **Nix flake** (`flake.nix`) provides all required tools reproducibly
- Enter development shell with `nix develop`
- Alternatively, use direnv with `echo "use flake" > .envrc && direnv allow`
- Without Nix, install tools manually (Docker 24+, act, actionlint, cosign, syft, trivy, grype)

**Workflow Validation**:
- **actionlint**: Validates GitHub Actions workflow YAML syntax
- Run `make lint-workflows` before pushing workflow changes
- Catches common errors: invalid syntax, missing permissions, incorrect job references

**Local CI Testing with act**:
- **act** runs GitHub Actions workflows locally using Docker
- Configuration in `.actrc` sets runner image and architecture
- Run `make test-ci` for quick validation of CI workflow
- Limitations: Different runner images, some features behave differently, secrets must be passed explicitly

**Build-Time Validation**:
- Dockerfile linting with Hadolint during local development
- Image structure validation with Dockle (optional, exit-code override for CI)
- Multi-architecture build verification via Buildx emulation (QEMU)

**Security Scanning**:
- **Trivy**: Fail builds on HIGH/CRITICAL CVEs (exit-code 1)
- **Grype**: Advisory scanning for additional CVE coverage
- **Nightly scans**: Recurring vulnerability monitoring for published images
- **SBOM validation**: Syft-generated CycloneDX artifacts attached to images

**Manual Testing Commands**:
```bash
# Enter Nix development shell (recommended)
nix develop

# Validate workflow syntax before pushing
make lint-workflows

# Run CI workflow locally
make test-ci

# Build and load single-platform image for local testing
make build TYPE=chainguard FLAVOR=jdk25

# Generate and inspect SBOM
make sbom TYPE=distroless FLAVOR=jdk26ea
cat sbom/distroless-jdk26ea.cdx.json | jq '.components[] | {name, version}'

# Run vulnerability scans locally
make scan TYPE=ubi9 FLAVOR=jdk25

# Verify runtime behavior
docker run --rm ghcr.io/artagon/artagon-containers:chainguard-jdk25 java --version
docker run --rm --read-only --tmpfs /tmp ghcr.io/artagon/artagon-containers:distroless-jre25 java -XshowSettings:vm -version
```

**Integration Testing**:
- PR builds: All 15 targets built for linux/amd64 only (load and scan)
- Main branch pushes: Full multi-arch build, sign, and publish
- Tag pushes: Release workflow with attestation and release notes

### Git Workflow

**Branch Strategy**:
- `main`: Production branch with protection rules
- Feature branches: `{type}/{issue-number}-{description}` (e.g., `fix/123-musl-fallback-retry`)
- No direct commits to main; all changes via pull requests

**Commit Message Format** (Semantic Commits):
```
<type>(<scope>): <subject>

[optional body]

Closes #<issue-number>
```

**Types**:
- `feat`: New image variant, build target, or capability
- `fix`: Bug fixes, build failures, security patches
- `docs`: Documentation updates
- `build`: Build system, Dockerfile, or Makefile changes
- `ci`: GitHub Actions workflow modifications
- `refactor`: Code restructuring without behavior changes
- `chore`: Dependency updates, maintenance tasks

**Scopes** (optional):
- `chainguard`, `distroless`, `ubi9`: Base-specific changes
- `jdk25`, `jdk26ea`, `jdk26valhalla`: JDK version-specific
- `scripts`, `workflows`, `makefile`: Build infrastructure
- `sbom`, `signing`, `scanning`: Security tooling

**Examples**:
```
feat(chainguard): add jdk26valhalla musl variant

fix(scripts): use Alpine builder for distroless musl variants
Closes #42

ci(workflows): add retry logic for distroless builder apk installs

docs(security): update hardening guidance for read-only rootfs
```

**PR Requirements**:
- Title must follow semantic commit format
- All CI checks must pass (build, scan, lint)
- Require approvals from maintainers for main branch merges
- Auto-close issues via "Closes #N" in commit messages

## Domain Context

### JVM Container Best Practices

**Security Hardening**:
- Run as non-root user (UID 65532 is a Kubernetes convention for "nobody")
- Drop all Linux capabilities with `--cap-drop=ALL`
- Enable `no-new-privileges` security option
- Mount root filesystem read-only with writable tmpfs for /tmp
- Pin base images by digest to prevent supply chain attacks

**JVM-Specific Considerations**:
- `JAVA_HOME` and `PATH` must be set for JDK discovery
- Distroless JRE images use jlink to create minimal custom runtimes
- Module system compatibility for JDK 9+ applications
- Container-aware JVM settings (automatic heap sizing since JDK 10)

**Image Size Optimization**:
- Chainguard: Full JDK (~300-400 MB) for build and runtime
- Distroless: jlink JRE (~150-200 MB) for runtime-only deployments
- UBI9: Enterprise support with larger footprint (~400-500 MB)

### Eclipse Temurin Distribution

Eclipse Adoptium (formerly AdoptOpenJDK) provides:
- TCK-certified OpenJDK builds
- Long-term support for LTS versions
- Multi-platform binaries with SHA256 checksums
- GPG signatures for verification
- Transparent build and test processes

**Licensing**:
- OpenJDK: GPLv2 with Classpath Exception
- No proprietary restrictions for production use
- Embedded license files in images per OCI label specification

### Supply Chain Security Model

**SLSA Framework** (Supply chain Levels for Software Artifacts):
- Level 1: Provenance generation with GitHub Actions attestations
- Level 2: Signed provenance with Cosign keyless signing
- Level 3: Hardened build platform (GitHub-hosted runners)

**SBOM Strategy**:
- CycloneDX format for ecosystem compatibility
- Embedded in OCI annotations via `org.opencontainers.image.sbom`
- Separate attestation artifacts signed with Cosign
- Nightly re-generation to track upstream dependency changes

**Verification Workflow**:
```bash
# Verify signature
COSIGN_EXPERIMENTAL=1 cosign verify ghcr.io/artagon/artagon-containers:chainguard-jdk25

# Download and inspect SBOM
cosign download sbom ghcr.io/artagon/artagon-containers:distroless-jre25 > sbom.json
syft scan --input sbom.json

# Verify SLSA provenance attestation
cosign verify-attestation --type slsaprovenance ghcr.io/artagon/artagon-containers:ubi9-jdk25
```

## Important Constraints

### Technical Constraints

**Multi-Architecture Builds**:
- Must support linux/amd64 and linux/arm64 simultaneously
- QEMU emulation required for cross-platform builds in CI
- Build times increase linearly with architecture count (~2x for dual-arch)

**Base Image Compatibility**:
- Chainguard: musl libc only (Alpine-based)
- Distroless: Separate glibc (base-debian12) and musl (static-debian12) bases
- UBI9: glibc only (RHEL-based)
- Cannot mix libc types in multi-stage builds (except Alpine builders for distroless)

**JDK Resolution Complexity**:
- Adoptium API for JDK 25 GA (stable, versioned releases)
- Artagon Homebrew taps for JDK 26 EA/Valhalla (frequent updates)
- Musl builds not always available; fallback to glibc with Alpine builder required
- Architecture naming inconsistencies across sources (x64, x86_64, amd64)

**Security Scanning Gates**:
- HIGH and CRITICAL CVEs fail builds immediately
- MEDIUM/LOW severities logged but do not block
- Base image vulnerabilities outside project control (rely on upstream patching)
- False positives require manual triage and Trivy ignore policies

### Business Constraints

**Licensing Compliance**:
- Must preserve and propagate Eclipse Temurin license notices
- OCI labels required for license attribution
- No redistribution of proprietary Oracle JDK builds

**Enterprise Support Requirements**:
- UBI9 images for customers requiring Red Hat support contracts
- Reproducible builds for audit and compliance verification
- SBOM and provenance for regulatory frameworks (HIPAA, SOC2, FedRAMP)

### Operational Constraints

**CI/CD Resource Limits**:
- GitHub Actions runner timeout: 60 minutes per job
- Matrix builds run in parallel (15 targets × ~10 minutes each)
- Rate limits on Adoptium API and Chainguard/Distroless registries
- Artifact storage costs for SBOMs and cache layers

**Maintenance Burden**:
- Upstream JDK releases every 6 months (JDK 27 in September 2025)
- Base image digest updates via Dependabot (weekly)
- Nightly vulnerability scans may trigger issues requiring investigation
- Coordination with Artagon tap maintainers for EA builds

## External Dependencies

### JDK Sources

**Eclipse Adoptium API** (JDK 25 GA):
- Endpoint: `https://api.adoptium.net/v3/assets/feature_releases/25/ga`
- Query parameters: architecture, os, image_type, jvm_impl
- Response format: JSON with download links, checksums, signatures
- Rate limits: Unauthenticated access sufficient for project needs
- SLA: Community-supported, no guaranteed uptime

**Artagon Homebrew Taps** (JDK 26 EA/Valhalla):
- Formula URLs: `https://github.com/artagon/homebrew-{jdk26ea,jdk26valhalla}`
- Format: Ruby DSL with embedded URLs and SHA256 hashes
- Update frequency: Weekly during EA cycle, varies by upstream releases
- Dependency: GitHub raw content API availability

### Base Image Registries

**Chainguard Images**:
- Registry: `cgr.dev/chainguard/wolfi-base`
- Authentication: Public images, no credentials required
- Update frequency: Daily security patches
- Digest pinning: Required due to rolling `latest` tag

**Google Container Registry (Distroless)**:
- Registry: `gcr.io/distroless/{base-debian12,static-debian12}`
- Authentication: Public read access
- Update frequency: Monthly or on-demand for CVE patches
- Variants: glibc (base) and musl-compatible (static)

**Red Hat Registry (UBI)**:
- Registry: `registry.access.redhat.com/ubi9-minimal`
- Authentication: Public access for UBI images
- Update frequency: Aligned with RHEL 9 patch schedule
- Support: Covered under Red Hat Enterprise Linux subscriptions

### Security Tooling

**Syft** (SBOM Generation):
- Distribution: Install script from `anchore/syft` GitHub releases
- Version pinning: None (latest stable)
- Output formats: CycloneDX JSON, SPDX, Syft JSON

**Trivy** (Vulnerability Scanning):
- Distribution: Install script from `aquasecurity/trivy` releases
- Database updates: Automatic on first run and daily refresh
- Exit codes: 0 (clean), 1 (vulnerabilities found)

**Grype** (Vulnerability Scanning):
- Distribution: Install script from `anchore/grype` releases
- Complementary to Trivy (different CVE databases)
- Output: Text summary and JSON reports

**Cosign** (Signing and Verification):
- Distribution: GitHub Actions `sigstore/cosign-installer`
- Keyless mode: Uses OIDC identity from GitHub Actions
- Experimental: Required for Rekor transparency log integration

### CI/CD Platform

**GitHub Actions**:
- Workflows: `.github/workflows/{build-push,nightly-scan,release}.yml`
- Runners: `ubuntu-latest` (GitHub-hosted)
- Permissions: `contents: read`, `packages: write`, `id-token: write` (for Cosign)
- Secrets: `GITHUB_TOKEN` (automatic), `COSIGN_EXPERIMENTAL=1` (env var)

**GitHub Container Registry**:
- Namespace: `ghcr.io/artagon/artagon-containers`
- Authentication: GitHub PAT or Actions GITHUB_TOKEN
- Visibility: Public images, no pull authentication required
- Retention: Unlimited for tagged releases

### Monitoring and Observability

**GitHub Issues**:
- Nightly scan workflow creates issues on new CVE detection
- Labels: `security`, `vulnerability`, `{base-type}`
- Automated triage: CVE severity and affected image tags

**GitHub Releases**:
- Triggered by Git tags matching semantic versioning
- Includes: Changelog, SBOM artifacts, signature verification instructions
- Notes: Auto-generated from commit messages since last release
