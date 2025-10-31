# Artagon Containers

Hardened OCI images for JVM workloads on Chainguard (Wolfi), Google Distroless, and Red Hat UBI 9 Minimal. Each variant ships preinstalled Temurin JDK 25 GA, JDK 26 Early Access, or JDK 26 Valhalla Early Access for both `linux/amd64` and `linux/arm64`, with musl builds where supported. Images are non-root, digest pinned, SBOM-attested, and Cosign-signed.

## Image Matrix

| Tag | Base | libc | Contents |
| --- | --- | --- | --- |
| `chainguard-jdk25` | `cgr.dev/chainguard/wolfi-base` | musl | Full JDK 25 GA |
| `chainguard-jdk25-musl` | same | musl | Musl toolchain (alias) |
| `chainguard-jdk26ea` | same | musl | JDK 26 EA |
| `chainguard-jdk26ea-musl` | same | musl | JDK 26 EA (alt tag) |
| `chainguard-jdk26valhalla` | same | musl | Valhalla EA |
| `chainguard-jdk26valhalla-musl` | same | musl | Valhalla EA (alt tag) |
| `distroless-jre25` | `gcr.io/distroless/base-debian12` | glibc | jlink JRE 25 |
| `distroless-jre25-musl` | `gcr.io/distroless/static-debian12` | musl | static jlink JRE 25 |
| `distroless-jre26ea` | `gcr.io/distroless/base-debian12` | glibc | jlink JRE 26 EA |
| `distroless-jre26ea-musl` | `gcr.io/distroless/static-debian12` | musl | static jlink JRE 26 EA |
| `distroless-jre26valhalla` | `gcr.io/distroless/base-debian12` | glibc | jlink Valhalla EA |
| `distroless-jre26valhalla-musl` | `gcr.io/distroless/static-debian12` | musl | static Valhalla EA |
| `ubi9-jdk25` | `registry.access.redhat.com/ubi9-minimal` | glibc | Full JDK 25 GA |
| `ubi9-jdk26ea` | same | glibc | JDK 26 EA |
| `ubi9-jdk26valhalla` | same | glibc | Valhalla EA |

Common properties:
- Non-root (`uid=65532`, `gid=65532`)
- `WORKDIR /workspace`
- Root filesystem mountable read-only (`--read-only --tmpfs /tmp`)
- Drops Linux capabilities & sets `no-new-privileges`
- `JAVA_HOME` and `PATH` exported
- OCI labels (`org.opencontainers.image.*`) including SBOM pointer and licenses

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

# Generate SBOM & sign
make sbom TYPE=chainguard FLAVOR=jdk26ea
make scan TYPE=chainguard FLAVOR=jdk26ea
make sign TYPE=chainguard FLAVOR=jdk26ea
```

Environment requirements: Docker 24+, Buildx/BuildKit, `jq`, `python3`, `curl`, `cosign`, `syft`, `trivy`, `grype`, `hadolint`, `dockle`.

## CI/CD

- `build-push.yml`: PR/main builds, SBOM, vulnerability gates, Cosign.
- `nightly-scan.yml`: recurring Trivy/Grype scans, auto-issues on new CVEs.
- `release.yml`: tag-driven publish with signed attestations & release notes.

## Security Posture

- Digest-pinned bases (see Dockerfiles)
- Syft CycloneDX SBOMs embedded via `org.opencontainers.image.sbom`
- Cosign keyless signatures + SLSA provenance attestation
- Trivy/Grype gating (HIGH/CRITICAL fail builds)
- Supply-chain policy in `policy/`
- Non-root, no capabilities, optional read-only rootfs

## Verification

```bash
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
