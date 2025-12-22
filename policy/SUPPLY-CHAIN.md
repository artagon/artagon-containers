# Supply Chain and Provenance

For a consolidated security overview, see `docs/security/overview.md`.

| Control | Description |
| --- | --- |
| Base Pinning | Dockerfiles pin base image digests and include `SOURCE_DATE_EPOCH` for reproducibility. |
| Artifact Resolution | `scripts/resolve_jdk.sh` fetches metadata from Artagon taps or Adoptium API with SHA verification. |
| Integrity | `scripts/verify_sha256.sh` enforces checksum matches before extraction. |
| SBOM | Syft CycloneDX SBOMs are generated and embedded via OCI labels. |
| Signing | Cosign keyless signatures and SLSA provenance attestations are published for each tag. |
| Scanning | Trivy and Grype scans block HIGH/CRITICAL vulnerabilities pre-publish; nightly re-scans monitor drift. |
| Dependency Updates | Dependabot monitors Docker base digests for updates. |

## FIPS 140-3 Roadmap

Supply-chain considerations for FIPS 140-3 alignment:
- Track and pin FIPS-validated base images and crypto modules when available
- Document provenance for FIPS variants and publish signed attestations
- Maintain a verification checklist for FIPS-mode builds and releases
