# Artagon Containers

Hardened OCI images for JVM workloads on Chainguard (Wolfi), Google Distroless, and Red Hat UBI 9 Minimal. Each variant ships preinstalled Temurin JDK 25 GA, JDK 26 Early Access, or JDK 26 Valhalla Early Access for both `linux/amd64` and `linux/arm64`, with musl builds where supported. Images are non-root, digest pinned, SBOM-attested, and Cosign-signed.

## CI Images vs. Deployment Images

This repository produces two distinct types of images to balance development speed with production security:

| Feature | CI Images (`ci-*`) | Deployment Images (Production) |
| :--- | :--- | :--- |
| **Purpose** | Pull Request validation, local testing | Production deployments |
| **Architecture** | `linux/amd64` only (fast build) | `linux/amd64` + `linux/arm64` |
| **Content** | Debug tools for Chainguard/UBI (`curl`, `netcat`, `bind-tools`); Distroless CI tags are identical to prod | Minimal, hardened (no extra tools) |
| **Security** | Scanned for CRITICAL CVEs only; not signed/attested | Full scan, Signed, SBOM, Attested |
| **Retention** | Ephemeral (can be deleted/overwritten) | Immutable, long-term retention |

**⚠️ WARNING:** Never deploy `ci-` prefixed images to production. They lack the full security verification of production builds and may include extra tools (Chainguard/UBI).

## Image Matrix

| Tag | Base | libc | Notes |
| --- | --- | --- | --- |
| `chainguard-jdk25` | `cgr.dev/chainguard/wolfi-base` | glibc | Full JDK 25 GA |
| `chainguard-jdk25-musl` | `alpine:3.20` | musl | Musl toolchain |
| `chainguard-jdk26ea` | `cgr.dev/chainguard/wolfi-base` | glibc | JDK 26 EA |
| `chainguard-jdk26ea-musl` | `cgr.dev/chainguard/wolfi-base` | glibc | Musl tag alias (no musl binaries) |
| `chainguard-jdk26valhalla` | `cgr.dev/chainguard/wolfi-base` | glibc | Valhalla EA |
| `chainguard-jdk26valhalla-musl` | `cgr.dev/chainguard/wolfi-base` | glibc | Musl tag alias (no musl binaries) |
| `distroless-jre25` | `gcr.io/distroless/base-debian12` | glibc | jlink JRE 25 |
| `distroless-jre25-musl` | `gcr.io/distroless/base-debian12` | glibc | jlink JRE 25 + musl loader |
| `distroless-jre26ea` | `gcr.io/distroless/base-debian12` | glibc | jlink JRE 26 EA |
| `distroless-jre26ea-musl` | `gcr.io/distroless/base-debian12` | glibc | Musl tag alias + musl loader |
| `distroless-jre26valhalla` | `gcr.io/distroless/base-debian12` | glibc | jlink Valhalla EA |
| `distroless-jre26valhalla-musl` | `gcr.io/distroless/base-debian12` | glibc | Musl tag alias + musl loader |
| `ubi9-jdk25` | `registry.access.redhat.com/ubi9-minimal` | glibc | Full JDK 25 GA |
| `ubi9-jdk26ea` | `registry.access.redhat.com/ubi9-minimal` | glibc | JDK 26 EA |
| `ubi9-jdk26valhalla` | `registry.access.redhat.com/ubi9-minimal` | glibc | Valhalla EA |

Notes:
- Base images are digest-pinned in the Dockerfiles.
- Distroless images use `base-debian12` for all tags; musl tags include the musl loader for musl-built JREs.

Common properties:
- Non-root (`uid=65532`, `gid=65532`)
- `WORKDIR /workspace`
- Root filesystem mountable read-only (`--read-only --tmpfs /tmp`)
- Drops Linux capabilities & sets `no-new-privileges`
- `JAVA_HOME` and `PATH` exported
- OCI labels (`org.opencontainers.image.*`) including SBOM pointer and licenses

## Build Dependency Versions

Build dependencies are pinned in Dockerfiles to keep builds reproducible and satisfy linting. Update these when base digests change.

Base images (digest-pinned):
- `cgr.dev/chainguard/wolfi-base@sha256:ae238a181d95804645919b2671d50ae77477efbfb299544491346e2911125aaf`
- `alpine:3.20@sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d`
- `gcr.io/distroless/base-debian12@sha256:9e9b50d2048db3741f86a48d939b4e4cc775f5889b3496439343301ff54cdba8`
- `registry.access.redhat.com/ubi9/ubi@sha256:dec374e05cc13ebbc0975c9f521f3db6942d27f8ccdf06b180160490eef8bdbc`
- `registry.access.redhat.com/ubi9-minimal@sha256:34880b64c07f28f64d95737f82f891516de9a3b43583f39970f7bf8e4cfa48b7`

Wolfi (glibc) packages used by Chainguard glibc images and Distroless builders:
- `curl=8.17.0-r0`
- `coreutils=9.9-r0`
- `bash=5.3-r3`
- `python-3.12=3.12.12-r3`
- `ca-certificates=20251003-r0`
- `binutils=2.45.1-r2` (Distroless builder)
- `glibc=2.42-r3` (Distroless builder)
- `glibc-locale-posix=2.42-r3` (Distroless builder)
- `libgcc=15.2.0-r3` (Distroless builder)
- `netcat-openbsd=1.234-r0` (CI debug tools)
- `bind-tools=9.20.17-r0` (CI debug tools)

Alpine 3.20 (musl) packages used by Chainguard JDK25 musl images:
- `curl=8.14.1-r2`
- `coreutils=9.5-r2`
- `bash=5.2.26-r0`
- `python3=3.12.12-r0`
- `ca-certificates=20250911-r0`
- `netcat-openbsd=1.226-r0` (CI debug tools)
- `bind-tools=9.18.41-r0` (CI debug tools)

UBI 9 builder packages:
- `curl-7.76.1-34.el9`
- `tar-2:1.34-7.el9`
- `coreutils-8.32-39.el9`
- `gzip-1.12-1.el9`
- `ca-certificates-2025.2.80_v9.0.305-91.el9`
- `python3-3.9.25-2.el9_7`

UBI 9 runtime tools come from the pinned base image digest (health checks and user setup rely on these):
- `coreutils-single-8.32-39.el9`
- `shadow-utils-4.9-15.el9`
- `sed-4.8-9.el9`
- `grep-3.6-5.el9`
- `gawk-5.1.0-6.el9`

UBI 9 CI debug tools (installed only for `BUILD_TARGET=ci`):
- `nmap-ncat-3:7.92-3.el9`
- `bind-utils-32:9.16.23-34.el9_7.1`

## Quick Usage

```bash
# Run Chainguard JDK 25
docker run --rm \
  --read-only --tmpfs /tmp \
  -v "$(pwd)/app:/workspace:ro" \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25 \
  java -jar /workspace/HelloWorld.jar
```

Distroless runtimes:

```bash
docker run --rm \
  ghcr.io/artagon/artagon-containers:distroless-jre26valhalla \
  java -XX:+EnablePreview --version
```

## Local Build

```bash
# (Optional) Print resolved metadata for a target
make resolve TYPE=chainguard FLAVOR=jdk26ea

# Build multi-arch manifest (Chainguard, JDK 26 EA)
make build TYPE=chainguard FLAVOR=jdk26ea

# Build fast single-arch CI image (includes debug tools)
make build-ci TYPE=chainguard FLAVOR=jdk26ea

# Generate SBOM & sign
make sbom TYPE=chainguard FLAVOR=jdk26ea
make scan TYPE=chainguard FLAVOR=jdk26ea
make sign TYPE=chainguard FLAVOR=jdk26ea
```

Environment requirements: Docker 24+, Buildx/BuildKit, `jq`, `python3`, `curl`, `cosign`, `syft`, `trivy`, `grype`, `hadolint`, `dockle`.
Linting note: `make lint` runs Dockle with `DOCKER_CONTENT_TRUST=1` to enforce signature verification.

## Development Environment

This project uses [Nix](https://nixos.org/) for reproducible development environments. All required tools are defined in `flake.nix`.

### Quick Start with Nix

```bash
# Enter development shell (installs all dependencies)
nix develop

# Or use direnv for automatic shell activation
echo "use flake" > .envrc
direnv allow
```

### Included Tools

The Nix development shell provides:
- **Container tools**: docker, docker-buildx
- **GitHub Actions testing**: act, actionlint
- **Security & signing**: cosign, syft, grype, trivy
- **Build tools**: gnumake, jq, yq-go, python3
- **GitHub CLI**: gh

### Without Nix

If not using Nix, install the tools listed in Environment requirements above manually or via your system package manager.

## Workflow Testing

Test GitHub Actions workflows locally before pushing to avoid CI failures.

### Lint Workflows

```bash
# Validate all workflow YAML files
make lint-workflows

# Or directly with actionlint
actionlint .github/workflows/*.yml
```

### Run CI Locally with act

[act](https://github.com/nektos/act) runs GitHub Actions locally using Docker.

```bash
# Run CI workflow for a single target
make test-ci

# Run specific workflow with custom target
act pull_request -W .github/workflows/ci-build.yml \
  --matrix target:ci-chainguard-jdk25 \
  -s GITHUB_TOKEN="$(gh auth token)"
```

### Configuration Files

- `.actrc` - Default act configuration (runner image, architecture)
- `flake.nix` - Nix development environment definition

### Limitations

- `act` uses different runner images than GitHub-hosted runners
- Some GitHub Actions features (caching, artifacts) may behave differently
- Secrets must be passed explicitly via `-s` flag
- Docker-in-Docker may require additional configuration

## Build Process and Tooling

Build pipeline overview:
1. Resolve JDK metadata and checksums (`scripts/resolve_jdk.sh`).
2. Build OCI images with Buildx Bake using digest-pinned bases (`docker-bake.hcl`, `Makefile`).
3. Generate SBOMs (CycloneDX) with Syft.
4. Scan images with Trivy and Grype.
5. Sign and attest images with Cosign (keyless, Rekor-backed).

Tooling used:
- Build: Docker Buildx/BuildKit, Bake (`docker-bake.hcl`)
- JDK resolution: `curl`, `python3`, `scripts/resolve_jdk.sh`
- SBOM: `syft`
- Vulnerability scan: `trivy`, `grype`
- Signing/attestation: `cosign`
- Linting: `hadolint`, `dockle`

References:
- Consolidated security overview: `docs/security/overview.md`
- Supply chain controls: `policy/SUPPLY-CHAIN.md`
- Security policy and SLAs: `policy/SECURITY.md`

## CI/CD

- `build-push.yml`: PR/main builds, SBOM, vulnerability gates, Cosign.
- `nightly-scan.yml`: recurring Trivy/Grype scans, auto-issues on new CVEs.
- `release.yml`: tag-driven publish with signed attestations & release notes.

## Security Posture

### Runtime Hardening
- **Non-root user**: UID 65532 (`nobody` convention)
- **No capabilities**: Images require zero Linux capabilities
- **Read-only rootfs**: Fully supports `--read-only` with tmpfs mounts
- **Health checks**: HEALTHCHECK instructions for orchestration
- **Seccomp profile**: `security/seccomp-java.json` restricts syscalls to Java essentials
- **AppArmor profile**: `security/apparmor-java.txt` restricts filesystem access

### Supply Chain Security
- **Digest-pinned bases**: All base images pinned by SHA256
- **SBOM attestations**: CycloneDX format generated by Syft
- **Cosign signatures**: Keyless signing with Rekor transparency log
- **SLSA provenance**: Level 3 provenance with GitHub Actions attestation
- **In-toto attestations**: JDK resolution, SBOM metadata, scan summaries
- **Vulnerability scanning**: Trivy/Grype with HIGH/CRITICAL gates
- **CVE response SLA**: 24h acknowledgment, 72h patch for CRITICAL CVEs

### Compliance
- **CIS Docker Benchmark**: Level 1 compliance (4.1, 5.3, 5.12, 5.21, 5.25)
- **NIST SP 800-190**: Container security guidelines
- **Regulatory**: HIPAA, PCI-DSS, FedRAMP ready (SBOM, provenance, audit trails)

See [Security Policy](policy/SECURITY.md) for complete details.

## Security Controls

Runtime controls:
- Non-root user, read-only rootfs support, and capability drop
- Seccomp (`security/seccomp-java.json`) and AppArmor (`security/apparmor-java.txt`) profiles
- Health checks for all images (Distroless uses exec-form JVM check)

Supply-chain controls:
- Digest-pinned base images
- SBOM generation (Syft, CycloneDX)
- Image scanning (Trivy, Grype)
- Cosign signing and SLSA provenance attestations

References:
- Consolidated security overview: `docs/security/overview.md`
- Deployment guidance: `docs/security/deployment.md`
- AppArmor usage: `docs/security/apparmor.md`
- UBI9 minimization review: `docs/security/ubi9-minimization.md`
- Security policy, supported images, and compliance mapping: `policy/SECURITY.md`
- Security profiles and hardening artifacts: `security/`

## FIPS 140-3 Roadmap

Future work toward FIPS 140-3 compliance:
- Add UBI FIPS base variants (OpenJDK + approved crypto modules)
- Validate JVM crypto providers against FIPS mode (OpenSSL, NSS, or BC FIPS as applicable)
- Provide hardened runtime guidance and validation checklists for FIPS-enabled deployments

## Verification

```bash
scripts/verify_supply_chain.sh ghcr.io/artagon/artagon-containers:chainguard-jdk26ea

COSIGN_EXPERIMENTAL=1 cosign verify \
  ghcr.io/artagon/artagon-containers:chainguard-jdk26ea

cosign download sbom ghcr.io/artagon/artagon-containers:distroless-jre25 > distroless-jre25.cdx.json
syft scan --input distroless-jre25.cdx.json

cosign verify-attestation --type slsaprovenance \
  ghcr.io/artagon/artagon-containers:ubi9-jdk25
```

## Updating JDK Bits

1. `make resolve FLAVOR=jdk25` (and `jdk26ea`, `jdk26valhalla`)
2. Review `.env/*` for new versions/SHA
3. Commit changes; CI validates and publishes on merge/tag

## License

Repository is Apache 2.0. Temurin binaries are GPLv2 with Classpath Exception; see per-image README files for notices.
