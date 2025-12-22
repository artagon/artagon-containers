# Security and Supply Chain Overview

This document consolidates the security policy, supply-chain controls, and security profile guidance.
For authoritative policy and SLAs, see `policy/SECURITY.md` and `policy/SUPPLY-CHAIN.md`.

## Supported Images

Tag | Supported
--- | ---
chainguard-jdk25 | ✅
chainguard-jdk26ea | ✅
chainguard-jdk26valhalla | ✅
distroless-jre25 | ✅
distroless-jre26ea | ✅
distroless-jre26valhalla | ✅
ubi9-jdk25 | ✅
ubi9-jdk26ea | ✅
ubi9-jdk26valhalla | ✅

## Vulnerability Reporting and SLAs

Report issues via GitHub Security Advisories or email security@artagon.dev with:
- Affected tag and digest
- Vulnerability description, severity, and CVE
- Reproduction steps, logs, and SBOM entry if possible

Response timelines:
- CRITICAL: acknowledge within 24h, patched within 72h
- HIGH: acknowledge within 48h, patched within 1 week
- MEDIUM/LOW: acknowledge within 1 week, patched in next release

Base image CVEs are tracked with upstream status and release notes when remediation is outside Artagon control.

## Runtime Hardening

Default runtime security posture:
- Non-root user (UID/GID 65532)
- Read-only rootfs supported with tmpfs mounts
- No Linux capabilities required
- Health checks (Chainguard and UBI variants)

Security profiles:
- Seccomp profile: `security/seccomp-java.json`
- AppArmor profile: `security/apparmor-java.txt`

## Seccomp Profile (Summary)

The seccomp profile allows JVM-required syscalls and blocks high-risk syscalls (e.g., `ptrace`, `bpf`, `process_vm_*`).
For full usage and troubleshooting, see `docs/security/seccomp.md`.

## AppArmor Profile (Summary)

The AppArmor profile limits file system access to JVM, workspace, and temp directories, while denying sensitive paths.
Example usage:

```bash
sudo apparmor_parser -r security/apparmor-java.txt
docker run --security-opt apparmor=artagon-java <image>
```

## Supply Chain and Provenance Controls

| Control | Description |
| --- | --- |
| Base Pinning | Dockerfiles pin base image digests and include `SOURCE_DATE_EPOCH` for reproducibility. |
| Artifact Resolution | `scripts/resolve_jdk.sh` fetches metadata from Artagon taps or Adoptium API with SHA verification. |
| Integrity | `scripts/verify_sha256.sh` enforces checksum matches before extraction. |
| SBOM | Syft CycloneDX SBOMs are generated and embedded via OCI labels. |
| Signing | Cosign keyless signatures and SLSA provenance attestations are published for each tag. |
| Scanning | Trivy and Grype scans block HIGH/CRITICAL vulnerabilities pre-publish; nightly re-scans monitor drift. |
| Dependency Updates | Dependabot monitors Docker base digests for updates. |

## Verification

```bash
COSIGN_EXPERIMENTAL=1 cosign verify \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25

cosign download sbom ghcr.io/artagon/artagon-containers:distroless-jre25 > sbom.json
syft scan --input sbom.json

cosign verify-attestation --type slsaprovenance \
  ghcr.io/artagon/artagon-containers:ubi9-jdk25

trivy image ghcr.io/artagon/artagon-containers:chainguard-jdk25
grype ghcr.io/artagon/artagon-containers:chainguard-jdk25
```

## Compliance Mapping

### CIS Docker Benchmark
- Non-root user → CIS 4.1
- Read-only rootfs → CIS 5.12
- Seccomp profile → CIS 5.21
- Capabilities dropped → CIS 5.3
- No new privileges → CIS 5.25

### NIST SP 800-190
- Image security (Section 4.1)
- Container runtime security (Section 4.2)
- Supply chain security (Section 4.4)

### Regulatory Alignment
- HIPAA: SBOM and provenance for audit trails
- PCI-DSS: Vulnerability scanning and patching SLA
- FedRAMP: SLSA Level 3 provenance, continuous monitoring

## Security Testing

- Vulnerability scanning: Trivy and Grype with HIGH/CRITICAL gates
- SBOM generation: CycloneDX format with package inventory
- Runtime testing: read-only rootfs and security profile validation
- Nightly scans: continuous monitoring for new CVEs

## References

- Security policy and SLAs: `policy/SECURITY.md`
- Supply-chain controls: `policy/SUPPLY-CHAIN.md`
- Seccomp profile usage: `docs/security/seccomp.md`
- Seccomp profile: `security/seccomp-java.json`
- AppArmor profile: `security/apparmor-java.txt`
