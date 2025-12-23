# Container Hardening Proposal

## Why

Current container images prioritize functionality over security hardening. Production deployments require defense-in-depth security controls to reduce attack surface, prevent runtime modifications, and meet compliance requirements (CIS benchmarks, NIST SP 800-190, HIPAA, SOC2, FedRAMP). Without comprehensive hardening, containers are vulnerable to privilege escalation, malware persistence, and lateral movement attacks.

## What Changes

This proposal implements industry-standard container security hardening across all image variants (Chainguard, Distroless, UBI9):

- **Security profiles**: Add seccomp and AppArmor profiles tailored for Java applications
- **Runtime restrictions**: Enforce read-only root filesystem, drop all capabilities, validate non-root execution
- **Health monitoring**: Add HEALTHCHECK instructions for orchestration integration
- **UBI9 minimization**: Evaluate ubi9-micro base and remove unnecessary packages
- **Security labels**: Add OCI labels documenting security posture and capabilities
- **Supply chain**: Enhance SLSA provenance to level 3 with in-toto attestations
- **Documentation**: Create comprehensive security policy (SECURITY.md) and deployment guides
- **Vulnerability management**: Strengthen scan thresholds and establish CVE response SLAs

**BREAKING CHANGES**:
- Deployment manifests must mount volumes for writable paths when using read-only rootfs
- Applications writing outside `/tmp` require explicit volume mounts
- Custom seccomp/AppArmor profiles may conflict with existing security policies

## Impact

**Affected specs**:
- `security-hardening` (NEW) - Security profiles, vulnerability management, supply chain
- `container-runtime` (NEW) - Runtime restrictions, health checks, filesystem requirements
- `deployment-guidance` (NEW) - Production deployment patterns, security configurations

**Affected code**:
- All Dockerfiles: `images/{chainguard,distroless,ubi9}/Dockerfile.*`
- Build workflows: `.github/workflows/{build-push,nightly-scan,release}.yml`
- Documentation: `README.md`, `policy/SECURITY.md`, `policy/SUPPLY-CHAIN.md`
- Security profiles: `security/seccomp-java.json`, `security/apparmor-java.txt` (NEW)

**Dependencies**:
- Seccomp profile testing requires Docker 20.10+ or Kubernetes 1.19+
- AppArmor testing requires AppArmor-enabled Linux kernel
- SLSA level 3 requires GitHub Actions workflow updates

**Risks**:
- Applications assuming writable root filesystem will fail
- Restrictive syscall filtering may break edge-case JVM features
- UBI9 minimization may remove packages needed by some workloads
- Increased build complexity and testing surface area

**Migration**:
- Update deployment manifests to include volume mounts for writable paths
- Test applications with hardening enabled before production rollout
- Provide documentation for opt-out scenarios (development environments)
