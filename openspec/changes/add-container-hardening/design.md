# Container Hardening Design

## Context

Container security hardening reduces attack surface and prevents post-compromise lateral movement. Industry frameworks (CIS Docker Benchmark, NIST SP 800-190) provide prescriptive guidance, but Java applications have unique requirements (JIT compilation, native libraries, signal handling) that require careful profile tuning.

**Stakeholders**:
- Security teams requiring compliance with CIS benchmarks
- Platform engineers deploying to regulated environments (HIPAA, SOC2, FedRAMP)
- Application developers needing compatibility with JVM features
- Operations teams responsible for container orchestration

**Constraints**:
- Must maintain compatibility with all JDK variants (JDK 25 GA, JDK 26 EA, Valhalla EA)
- Cannot break existing deployments without documented migration path
- Security profiles must work across amd64 and arm64 architectures
- Must integrate with existing CI/CD and signing workflows

## Goals / Non-Goals

**Goals**:
- Implement CIS Docker Benchmark Level 1 compliance
- Provide defense-in-depth through multiple security layers
- Enable read-only root filesystem for immutable deployments
- Restrict syscall surface area to necessary operations
- Integrate with Kubernetes security contexts seamlessly
- Document security posture transparently via OCI labels

**Non-Goals**:
- Custom JVM security manager configurations (deprecated in JDK 17+)
- SELinux policies (too environment-specific; leave to deployment layer)
- Network policies or service mesh integration (out of scope)
- Runtime application firewall (belongs in application layer)
- Per-application seccomp profiles (provide baseline Java profile)

## Decisions

### Decision 1: Seccomp Profile Approach

**Choice**: Create single `seccomp-java.json` baseline profile allowing common JVM syscalls

**Rationale**:
- Java requires ~100 syscalls for JIT, signal handling, thread management, file I/O
- Blocking dangerous syscalls (ptrace, personality, bpf, perf_event_open) reduces kernel attack surface
- Docker default seccomp blocks ~44 of ~300+ syscalls; we can tighten further
- Single profile simpler to maintain than per-JDK-version profiles

**Alternatives considered**:
- Per-application profiles: Too burdensome; users can extend baseline
- Docker default only: Insufficient; doesn't block ptrace, process_vm_readv
- No seccomp: Fails CIS benchmark 5.21

**Implementation**:
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_AARCH64"],
  "syscalls": [
    {"names": ["read", "write", "open", "close", "mmap", ...], "action": "SCMP_ACT_ALLOW"}
  ]
}
```

**Testing strategy**:
- Run test applications (Spring Boot, Micronaut, Quarkus) with profile
- Monitor audit logs for blocked syscalls
- Validate JIT compilation, class loading, thread creation work
- Test both amd64 and arm64

### Decision 2: AppArmor Profile Scope

**Choice**: Create restrictive `apparmor-java.txt` profile allowing read access to JDK paths and write to `/tmp` only

**Rationale**:
- AppArmor provides filesystem-level access control beyond Linux capabilities
- Java applications typically read from JDK installation and write to `/tmp`
- Restricting network access via AppArmor overlaps with network policies (leave to orchestration)
- Profile must be loaded on host before container start (document requirement)

**Alternatives considered**:
- No AppArmor: Loses defense-in-depth; only seccomp restricts syscalls
- Include network restrictions: Conflicts with service mesh sidecars
- Per-base-image profiles: Unnecessary; all use same JDK layout

**Implementation**:
```
#include <tunables/global>

profile artagon-java flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  /usr/lib/jvm/** r,
  /workspace/** r,
  /tmp/** rw,
  /dev/urandom r,

  deny /etc/shadow r,
  deny /root/** rwx,
  deny @{HOME}/.ssh/** rwx,
}
```

**Testing strategy**:
- Test with AppArmor-enabled Ubuntu/Debian hosts
- Verify profile loads correctly: `sudo apparmor_parser -r apparmor-java.txt`
- Run containers with `--security-opt apparmor=artagon-java`
- Validate file access restrictions work

### Decision 3: Read-Only Rootfs Strategy

**Choice**: Document and recommend read-only rootfs; do not enforce in Dockerfile

**Rationale**:
- Read-only rootfs is runtime configuration (`--read-only` flag or Kubernetes `readOnlyRootFilesystem`)
- Cannot enforce in image; requires coordination with orchestration platform
- Java applications require writable `/tmp` for class caching, native libraries
- Provide clear documentation and example manifests

**Alternatives considered**:
- Enforce in ENTRYPOINT script: Cannot override runtime; too rigid
- Create separate "hardened" image variants: Doubles maintenance burden
- Ignore read-only rootfs: Misses key security hardening

**Implementation**:
- Add OCI label: `org.opencontainers.image.security.readonly-rootfs=recommended`
- Document required tmpfs mounts: `/tmp`
- Provide Kubernetes example:
```yaml
securityContext:
  readOnlyRootFilesystem: true
volumeMounts:
  - name: tmp
    mountPath: /tmp
volumes:
  - name: tmp
    emptyDir: {}
```

**Testing strategy**:
- Test all images with `docker run --read-only --tmpfs /tmp`
- Verify JVM starts, loads classes, executes successfully
- Test with real applications (Spring Boot JAR)

### Decision 4: HEALTHCHECK Configuration

**Choice**: Add simple version check as HEALTHCHECK in all Dockerfiles

**Rationale**:
- Kubernetes and Docker Compose use HEALTHCHECK for liveness/readiness probes
- Java version check is lightweight (~10ms) and confirms JVM is functional
- Applications should override with application-specific health endpoints
- Provides baseline health check for images used standalone

**Alternatives considered**:
- No HEALTHCHECK: Misses orchestration integration opportunity
- HTTP-based health check: Assumes application has HTTP endpoint (not always true)
- Complex JVM diagnostics: Too slow for frequent health checks

**Implementation**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["java", "-XshowSettings:properties", "-version"] || exit 1
```

**Testing strategy**:
- Run containers and verify health status: `docker ps` (healthy/unhealthy)
- Test with failing JVM (remove java binary, chmod)
- Validate Kubernetes uses HEALTHCHECK for liveness probes

### Decision 5: UBI9 Minimization Approach

**Choice**: Audit current packages, remove dev tools, evaluate ubi9-micro for future migration

**Rationale**:
- UBI9 minimal still includes ~150MB of packages; ubi9-micro is ~80MB
- Removing unnecessary packages reduces CVE surface area
- ubi9-micro may be too minimal (missing CA certs, tzdata by default)
- Conservative approach: document packages, remove obvious bloat (e.g., yum, subscription-manager)

**Alternatives considered**:
- Immediate ubi9-micro migration: Too risky; may break workloads
- Leave as-is: Misses size and security improvements
- Match Chainguard size: Different philosophies; UBI includes Red Hat support packages

**Implementation**:
```dockerfile
RUN microdnf remove -y yum subscription-manager \
 && microdnf clean all \
 && rm -rf /var/cache/dnf
```

**Testing strategy**:
- Compare package counts and sizes before/after
- Run test workloads to verify functionality
- Scan for CVE count reduction
- Document size savings in CHANGELOG

### Decision 6: SLSA Level 3 Provenance

**Choice**: Use `slsa-github-generator` reusable workflow for Level 3 provenance

**Rationale**:
- SLSA Level 3 requires isolated build environment with provenance generation
- GitHub's official generator provides turnkey solution
- Reusable workflow runs in separate job with OIDC attestation
- Integrates with existing Cosign signing workflow

**Alternatives considered**:
- Manual provenance generation: Complex, error-prone, hard to verify
- SLSA Level 2 only: Doesn't meet highest compliance standards
- Third-party CI (Tekton, GitLab): Platform lock-in

**Implementation**:
```yaml
provenance:
  uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@v2.0.0
  with:
    image: ${{ needs.build.outputs.digest }}
    registry-username: ${{ github.actor }}
  secrets:
    registry-password: ${{ secrets.GITHUB_TOKEN }}
```

**Testing strategy**:
- Verify provenance attestation created
- Validate with `cosign verify-attestation --type slsaprovenance`
- Confirm provenance includes builder identity, materials, parameters

## Risks / Trade-offs

### Risk 1: Application Compatibility

**Risk**: Restrictive seccomp profile blocks syscalls needed by specific JVM features or native libraries

**Likelihood**: Medium (Java ecosystem has wide variety of native dependencies)

**Impact**: High (applications fail to start or crash at runtime)

**Mitigation**:
- Test with popular frameworks (Spring, Micronaut, Quarkus, Vert.x)
- Document how to identify blocked syscalls: `dmesg | grep audit`
- Provide guidance for extending baseline profile
- Monitor GitHub issues for compatibility reports

### Risk 2: Read-Only Rootfs Migration Burden

**Risk**: Users with applications writing to non-standard paths must update deployment manifests

**Likelihood**: High (many applications assume writable filesystem)

**Impact**: Medium (deployment failures, requires manifest changes)

**Mitigation**:
- Comprehensive documentation with examples
- Detect and log writes to unexpected paths during testing
- Provide troubleshooting guide for common issues
- Clearly mark as **BREAKING CHANGE** in release notes

### Risk 3: UBI9 Package Removal Side Effects

**Risk**: Removing packages breaks workloads that depend on them (e.g., CA certs, tzdata, curl)

**Likelihood**: Low (conservative approach, only removing obvious bloat)

**Impact**: High (TLS connections fail, timezone issues)

**Mitigation**:
- Whitelist approach: only remove known-unnecessary packages
- Test TLS connections to public APIs
- Verify timezone database present
- Document all removed packages in CHANGELOG

### Risk 4: Security Profile Testing Gaps

**Risk**: Tests don't catch edge cases where profiles block legitimate functionality

**Likelihood**: Medium (impossible to test all workload combinations)

**Impact**: Medium (runtime failures for subset of users)

**Mitigation**:
- Community testing period before marking stable
- Provide opt-out mechanism (document how to disable profiles)
- Collect telemetry on blocked syscalls in test environments
- Establish issue response SLA

## Migration Plan

### Phase 1: Additive Security Features (Non-Breaking)

1. Add HEALTHCHECK to all Dockerfiles
2. Add security labels to images
3. Publish seccomp and AppArmor profiles in repository
4. Update documentation with hardening recommendations
5. CI validates profiles apply successfully (but doesn't enforce)

**Rollback**: Remove HEALTHCHECK and labels in next build

### Phase 2: UBI9 Minimization (Low-Risk Breaking)

1. Create `ubi9-jdk25-minimal` tag with package removal
2. Run parallel builds of standard and minimal variants
3. Scan both for CVE count comparison
4. Community testing period (2 weeks)
5. Replace standard variant if no issues reported

**Rollback**: Revert Dockerfile changes, rebuild standard variant

### Phase 3: Documentation and Tooling (Non-Breaking)

1. Publish comprehensive security guide
2. Add verification scripts to repository
3. Implement SLSA Level 3 in release workflow
4. Update SECURITY.md with CVE response SLA

**Rollback**: N/A (documentation only)

### Phase 4: Enforce Read-Only Rootfs Testing (CI-Only)

1. Add CI job testing all images with `--read-only --tmpfs /tmp`
2. Fail builds if images don't support read-only rootfs
3. Update issue templates to request read-only rootfs compatibility

**Rollback**: Remove CI job

### User Migration Steps

For users upgrading to hardened images:

1. **Review deployment manifests**: Identify applications writing outside `/tmp`
2. **Add volume mounts**: Mount emptyDir or PVC for writable paths
3. **Test in staging**: Deploy with `readOnlyRootFilesystem: true` enabled
4. **Apply security profiles**: Load seccomp/AppArmor profiles on hosts
5. **Update security contexts**: Add `capabilities.drop: [ALL]`
6. **Monitor logs**: Check for blocked syscalls or permission denied errors
7. **Adjust profiles if needed**: Extend baseline profiles for application needs

## Open Questions

1. **Seccomp Profile Maintenance**: Who reviews and approves syscall additions as new JVM versions release?
   - **Proposed Answer**: Designate security maintainer, require CVE justification for new syscalls

2. **AppArmor vs SELinux**: Should we also provide SELinux policies for RHEL-based deployments?
   - **Proposed Answer**: Defer to Phase 2; SELinux is more environment-specific (requires types, contexts)

3. **SLSA Level 4**: Is there demand for Level 4 (two-person review, hermetic builds)?
   - **Proposed Answer**: Wait for user feedback; Level 3 meets most compliance requirements

4. **Distroless HEALTHCHECK**: Distroless images lack shell; how to implement HEALTHCHECK?
   - **Proposed Answer**: Use `CMD []` form with direct binary execution; no shell needed

5. **Backward Compatibility Timeline**: How long to maintain non-hardened images?
   - **Proposed Answer**: Hardening is non-breaking (runtime opt-in); no separate variants needed
