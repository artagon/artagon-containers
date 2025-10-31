# Security Policy

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

## Reporting a Vulnerability

Please open a security advisory via GitHub or email security@artagon.dev with:
- Affected tag and digest
- Vulnerability description, severity, and CVE
- Reproduction steps, logs, and SBOM entry if possible

We aim to respond within 2 business days and ship fixes or mitigations within 7.

## Hardening Guidance

- Run containers with `--read-only --tmpfs /tmp:rw,exec,nosuid,nodev`
- Add `--security-opt=no-new-privileges:true`
- Drop capabilities via `--cap-drop=ALL`
- Pin digests in deployment manifests
- Verify Cosign signatures and SLSA provenance before rollout
