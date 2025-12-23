# deployment-guidance Specification

## Purpose
TBD - created by archiving change add-container-hardening. Update Purpose after archive.
## Requirements
### Requirement: Secure Deployment Examples

Documentation SHALL provide comprehensive examples of secure container deployment configurations for Docker, Docker Compose, and Kubernetes.

#### Scenario: Docker secure deployment example

- **WHEN** user references documentation for Docker deployment
- **THEN** documentation SHALL include example command with security flags:
  ```bash
  docker run --rm \
    --read-only --tmpfs /tmp \
    --cap-drop=ALL \
    --security-opt no-new-privileges \
    --security-opt seccomp=security/seccomp-java.json \
    -v "$(pwd)/app:/workspace:ro" \
    ghcr.io/artagon/artagon-containers:<tag> \
    java -jar /workspace/app.jar
  ```
- **AND** documentation SHALL explain each security flag's purpose

#### Scenario: Kubernetes secure deployment example

- **WHEN** user references documentation for Kubernetes deployment
- **THEN** documentation SHALL include example manifest with security contexts:
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: secure-java-app
  spec:
    securityContext:
      runAsNonRoot: true
      runAsUser: 65532
      runAsGroup: 65532
      fsGroup: 65532
    containers:
    - name: app
      image: ghcr.io/artagon/artagon-containers:<tag>
      securityContext:
        readOnlyRootFilesystem: true
        allowPrivilegeEscalation: false
        capabilities:
          drop: [ALL]
      volumeMounts:
      - name: tmp
        mountPath: /tmp
    volumes:
    - name: tmp
      emptyDir: {}
  ```
- **AND** documentation SHALL explain Kubernetes security context options

#### Scenario: Docker Compose secure deployment example

- **WHEN** user references documentation for Docker Compose deployment
- **THEN** documentation SHALL include example compose file with security settings
- **AND** example SHALL demonstrate read_only, tmpfs, cap_drop, security_opt configurations
- **AND** documentation SHALL note Docker Compose version requirements

### Requirement: Security Profile Loading Instructions

Documentation SHALL provide instructions for loading and verifying seccomp and AppArmor profiles on container hosts.

#### Scenario: Seccomp profile usage instructions

- **WHEN** user wants to apply seccomp profile
- **THEN** documentation SHALL explain how to reference profile with `--security-opt seccomp=`
- **AND** documentation SHALL provide examples for both file path and inline JSON
- **AND** documentation SHALL explain how to verify profile is applied

#### Scenario: AppArmor profile loading instructions

- **WHEN** user wants to apply AppArmor profile
- **THEN** documentation SHALL provide commands to load profile on host:
  ```bash
  sudo apparmor_parser -r security/apparmor-java.txt
  aa-status | grep artagon-java
  ```
- **AND** documentation SHALL explain how to verify profile is loaded
- **AND** documentation SHALL note AppArmor availability on Ubuntu/Debian

#### Scenario: Profile troubleshooting guidance

- **WHEN** user encounters errors with security profiles
- **THEN** documentation SHALL provide troubleshooting steps
- **AND** documentation SHALL explain how to view audit logs for blocked operations
- **AND** documentation SHALL provide guidance for extending profiles

### Requirement: Production Security Checklist

Documentation SHALL provide a comprehensive security checklist for production deployments covering all hardening features.

#### Scenario: Pre-deployment security checklist

- **WHEN** user prepares for production deployment
- **THEN** documentation SHALL provide checklist including:
  - [ ] Verify image signature with Cosign
  - [ ] Review SBOM for known vulnerabilities
  - [ ] Enable read-only root filesystem with tmpfs mounts
  - [ ] Drop all Linux capabilities
  - [ ] Apply seccomp profile
  - [ ] Apply AppArmor profile (if available)
  - [ ] Configure health checks
  - [ ] Set resource limits (CPU, memory)
  - [ ] Configure logging and monitoring
  - [ ] Test disaster recovery procedures

#### Scenario: Runtime security validation

- **WHEN** application is deployed to production
- **THEN** documentation SHALL provide validation commands:
  ```bash
  # Verify non-root user
  docker exec <container> id

  # Verify read-only rootfs
  docker inspect <container> | jq '.[].HostConfig.ReadonlyRootfs'

  # Verify capabilities dropped
  docker inspect <container> | jq '.[].HostConfig.CapDrop'

  # Verify seccomp profile
  docker inspect <container> | jq '.[].HostConfig.SecurityOpt'
  ```
- **AND** documentation SHALL explain expected output for each validation

### Requirement: Compliance Framework Mapping

Documentation SHALL map container hardening features to relevant compliance frameworks (CIS Docker Benchmark, NIST SP 800-190, PCI-DSS, HIPAA).

#### Scenario: CIS Docker Benchmark mapping

- **WHEN** user reviews security documentation
- **THEN** documentation SHALL map hardening features to CIS Docker Benchmark controls:
  - Non-root user → CIS 4.1
  - Read-only rootfs → CIS 5.12
  - Seccomp profile → CIS 5.21
  - Capabilities dropped → CIS 5.3
  - No new privileges → CIS 5.25
- **AND** documentation SHALL indicate compliance level (Level 1 or Level 2)

#### Scenario: NIST SP 800-190 mapping

- **WHEN** user reviews security documentation
- **THEN** documentation SHALL map hardening features to NIST SP 800-190 recommendations
- **AND** documentation SHALL reference specific sections (e.g., 4.1 Image Security)

#### Scenario: Regulatory compliance guidance

- **WHEN** user deploys to regulated environment (HIPAA, PCI-DSS, FedRAMP)
- **THEN** documentation SHALL provide guidance on relevant security controls
- **AND** documentation SHALL reference SLSA provenance and SBOM attestations for audit trails

### Requirement: Vulnerability Verification Instructions

Documentation SHALL provide instructions for users to independently verify image security and validate vulnerability scan results.

#### Scenario: Cosign signature verification

- **WHEN** user wants to verify image authenticity
- **THEN** documentation SHALL provide command:
  ```bash
  COSIGN_EXPERIMENTAL=1 cosign verify \
    ghcr.io/artagon/artagon-containers:<tag>
  ```
- **AND** documentation SHALL explain expected output indicating valid signature
- **AND** documentation SHALL note Rekor transparency log integration

#### Scenario: SBOM download and inspection

- **WHEN** user wants to review image components
- **THEN** documentation SHALL provide commands:
  ```bash
  cosign download sbom ghcr.io/artagon/artagon-containers:<tag> > sbom.json
  syft scan --input sbom.json
  ```
- **AND** documentation SHALL explain SBOM format (CycloneDX)
- **AND** documentation SHALL show how to query specific components

#### Scenario: Independent vulnerability scanning

- **WHEN** user wants to perform independent security scan
- **THEN** documentation SHALL provide example commands with multiple scanners:
  ```bash
  trivy image ghcr.io/artagon/artagon-containers:<tag>
  grype ghcr.io/artagon/artagon-containers:<tag>
  docker scout cves ghcr.io/artagon/artagon-containers:<tag>
  ```
- **AND** documentation SHALL explain how to interpret scan results
- **AND** documentation SHALL note that base image vulnerabilities are outside project control

### Requirement: Migration Guide for Hardened Deployments

Documentation SHALL provide step-by-step migration guide for users upgrading existing deployments to use hardening features.

#### Scenario: Migration from non-hardened deployment

- **WHEN** user has existing deployment without hardening
- **THEN** documentation SHALL provide migration steps:
  1. Review application for filesystem write patterns
  2. Test in staging with read-only rootfs enabled
  3. Identify and mount writable volumes
  4. Apply security profiles incrementally
  5. Validate functionality at each step
  6. Deploy to production with monitoring

#### Scenario: Breaking change identification

- **WHEN** user reviews migration guide
- **THEN** documentation SHALL clearly identify breaking changes:
  - Applications writing outside `/tmp` require volume mounts
  - Custom seccomp profiles may need adjustment
  - Health check may conflict with application startup time
- **AND** documentation SHALL provide workarounds or alternatives

#### Scenario: Rollback procedure

- **WHEN** hardened deployment encounters issues
- **THEN** documentation SHALL provide rollback steps:
  1. Remove read-only rootfs constraint
  2. Remove security profile options
  3. Restore previous Kubernetes manifest
  4. Investigate issues with relaxed constraints
  5. Apply hardening incrementally after fixing issues
- **AND** documentation SHALL note that image changes are non-breaking (hardening is runtime configuration)

### Requirement: Performance Impact Documentation

Documentation SHALL document performance characteristics and overhead of security hardening features.

#### Scenario: Seccomp overhead measurement

- **WHEN** user reviews performance documentation
- **THEN** documentation SHALL provide seccomp overhead metrics (e.g., <1% CPU overhead for syscall filtering)
- **AND** documentation SHALL note that overhead is negligible for typical Java applications

#### Scenario: Read-only rootfs performance

- **WHEN** user reviews performance documentation
- **THEN** documentation SHALL note that read-only rootfs may improve performance (reduced I/O contention)
- **AND** documentation SHALL note tmpfs mount performance characteristics (memory-backed)

#### Scenario: Health check resource usage

- **WHEN** user reviews performance documentation
- **THEN** documentation SHALL document health check resource usage (10ms per check, negligible CPU)
- **AND** documentation SHALL provide guidance on tuning check intervals for performance-sensitive workloads

