PROMPT.md — Create `artagon-containers` (Chainguard, Distroless, UBI Minimal) with pre-installed JDK 26 EA & Valhalla and JDK 25

You are an elite DevOps/containers engineer. Generate a complete GitHub repository named **`artagon-containers`** for building, signing, scanning, and publishing **OCI images** for **three secure bases**:

- **Chainguard (Wolfi) minimal**
- **Google Distroless (custom runtime)**
- **Red Hat UBI 9 Minimal**

Each image must ship **JDK 25**, **JDK 26 EA** and **JDK 26 Valhalla EA** *pre-installed* (both glibc & musl flavors where applicable), using versions/URLs resolved from these taps:

- https://github.com/artagon/homebrew-jdk26ea  
- https://github.com/artagon/homebrew-jdk26valhalla

> Do **not** rely on Homebrew inside the containers. Read the tap formulae to resolve version, URL and SHA256, then download the official Linux tarballs in a **builder stage**, verify checksums/signatures, and copy into the final image. Prefer **jlink**-minimized runtimes for Distroless.

---

## High-Level Requirements

- **Languages/Tools**: Dockerfiles + BuildKit/buildx, `docker bake`, GitHub Actions, Cosign (keyless), Trivy and Grype scans, Syft SBOMs (CycloneDX v1.6), SLSA provenance.
- **Architectures**: `linux/amd64` and `linux/arm64`.
- **Tags**:
  - `chainguard-jdk25`, `chainguard-jdk26ea`, `chainguard-jdk26valhalla`
  - `distroless-jre25`, `distroless-jre26ea`, `distroless-jre26valhalla`
  - `ubi9-jdk25`, `ubi9-jdk26ea`, `ubi9-jdk26valhalla`
  - Add `-musl` suffix where relevant (Chainguard musl; Distroless is glibc by default—also build a musl variant using `static` profile when feasible).
- **Security defaults**: non-root user, read-only rootfs (example `--read-only` guidance), drop all caps, `no-new-privileges`, pinned digest bases, build timestamps set via `SOURCE_DATE_EPOCH`.
- **Attestations**: Cosign keyless `sig` + `attestation` (SLSA provenance) + in-image SBOM label (`org.opencontainers.image.sbom`).
- **Licensing**: Include LICENSE, NOTICE for JDK binaries; embed `org.opencontainers.image.licenses` label.
- **Docs**: Clear README with usage, runtime flags, and validation steps.

---

## Repository Layout

artagon-containers/
├─ docker-bake.hcl
├─ Makefile
├─ .github/
│  └─ workflows/
│     ├─ build-push.yml
│     ├─ nightly-scan.yml
│     └─ release.yml
├─ .github/ISSUE_TEMPLATE/bug.md
├─ .github/ISSUE_TEMPLATE/feature.md
├─ .github/dependabot.yml
├─ .reuse/
├─ policy/SECURITY.md
├─ policy/SUPPLY-CHAIN.md
├─ scripts/
│  ├─ resolve_jdk.sh
│  ├─ verify_sha256.sh
│  ├─ create_jre.sh
│  └─ print_versions.sh
├─ images/
│  ├─ chainguard/
│  │  ├─ Dockerfile.jdk25
│  │  ├─ Dockerfile.jdk26ea
│  │  ├─ Dockerfile.jdk26valhalla
│  │  └─ README.md
│  ├─ distroless/
│  │  ├─ Dockerfile.jre25
│  │  ├─ Dockerfile.jre26ea
│  │  ├─ Dockerfile.jre26valhalla
│  │  └─ README.md
│  └─ ubi9/
│     ├─ Dockerfile.jdk25
│     ├─ Dockerfile.jdk26ea
│     ├─ Dockerfile.jdk26valhalla
│     └─ README.md
├─ sbom/
└─ README.md

---

## Implementation Details

### 1. Version/URL Resolution
- `scripts/resolve_jdk.sh`:
  - Fetch and parse the formulae in the two taps.
  - Output `version`, `url`, `sha256`, `signature`.
  - Support `--flavor=jdk25|jdk26ea|jdk26valhalla`, `--arch=amd64|arm64`, `--libc=glibc|musl`.
  - Produce `.env` files for Docker `--build-arg`.

### 2. Checksum/Signature Verification
- `scripts/verify_sha256.sh` validates tarball against formula hash.
- Verify GPG signatures if available.

### 3. jlink Minimization (Distroless)
- `scripts/create_jre.sh`:
  - Run `jlink` to produce minimal runtime:
    - Include `java.base`, `java.logging`, `jdk.crypto.ec`, `jdk.crypto.cryptoki`, `jdk.management`, `jdk.unsupported`.
  - Strip debug, docs, and headers.

### 4. Users, Paths, Labels
- JDK installed under `/usr/lib/jvm/jdk-<flavor>`
- Non-root user `65532:65532`
- OCI Labels:
  - `org.opencontainers.image.title`, `url`, `licenses`, `sbom`, etc.

---

## Base Image Strategies

### Chainguard (Wolfi)
- Multi-stage:
  - `cgr.dev/chainguard/wolfi-base:latest`
  - Install curl, ca-certificates, tar, coreutils.
  - Copy JDK to `/usr/lib/jvm`.

### Google Distroless
- Multi-stage:
  - Builder: Chainguard or UBI.
  - Final: `gcr.io/distroless/base` or `static`.
  - Copy JRE to `/usr/lib/jvm/jre-<flavor>`.

### Red Hat UBI Minimal
- Multi-stage:
  - Base: `registry.access.redhat.com/ubi9-minimal:latest`.
  - Copy JDK, register alternatives.

---

## Security & Compliance

- Non-root user, read-only FS, drop caps.
- SBOM via Syft (CycloneDX v1.6).
- Vulnerability scans via Trivy & Grype.
- Cosign keyless signing & SLSA attestations.
- `SECURITY.md` and `SUPPLY-CHAIN.md` with threat model.

---

## Build Orchestration

### `docker-bake.hcl`
- Define all targets and flavors.
- Common args: `JDK_URL`, `SHA256`, `FLAVOR`, `LIBC`, etc.
- Multi-arch build matrix.

### `Makefile`
- Targets:
  - `make resolve`
  - `make build TYPE=chainguard FLAVOR=jdk26ea`
  - `make sbom`
  - `make sign`
  - `make push`

---

## GitHub Workflows

### build-push.yml
- Trigger on PRs and main.
- Setup QEMU/buildx.
- Resolve JDK versions.
- Bake multi-arch builds.
- Cosign sign+attest.
- Upload SBOMs.

### nightly-scan.yml
- Nightly Trivy/Grype.
- Auto-create issues on new CVEs.

### release.yml
- Trigger on tag.
- Release multi-arch manifests.
- Publish SBOMs & digests in Release notes.

---

## README Requirements

- Explain image matrix and tags.
- Usage examples (`docker run ...`).
- Signature verification with Cosign.
- Provenance verification.
- CVE tracking.

---

## Quality Gates

- Hadolint & Dockle.
- CVE gating (block High/Critical).
- Multi-arch build test.
- Cosign signature verification.
- Dependabot for digest bumps.

---

## Acceptance Criteria

- Builds multi-arch reproducibly.
- Signed + attested images on `ghcr.io/<owner>/artagon-containers`.
- CycloneDX SBOM attached.
- Verified digest pins.
- README shows zero CVEs and build reproducibility proof.

---

## Optional Enhancements

- FIPS variants for UBI.
- Image size reports.
- OSSF/Scorecard badge.
- Integration tests with simple HelloWorld JAR.

---

## Output

Generate **all files** and **ready-to-run content** for this repository, including Dockerfiles, scripts, bakefile, Makefile, and workflows.  
Each component must be functional, secure-by-default, and reproducible with provenance.
