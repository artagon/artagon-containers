# security-hardening Specification

## Purpose
TBD - created by archiving change add-container-hardening. Update Purpose after archive.
## Requirements
### Requirement: Seccomp Profile for Java Applications

The project SHALL provide a seccomp profile (`security/seccomp-java.json`) that restricts container syscalls to those necessary for JVM operation while blocking dangerous operations.

#### Scenario: Profile blocks dangerous syscalls

- **WHEN** container runs with `--security-opt seccomp=security/seccomp-java.json`
- **THEN** syscalls like `ptrace`, `personality`, `bpf`, `perf_event_open`, `process_vm_readv` SHALL be blocked
- **AND** Java process continues to function normally

#### Scenario: Profile allows essential Java syscalls

- **WHEN** Java application performs JIT compilation, thread management, file I/O, or signal handling
- **THEN** required syscalls (read, write, mmap, futex, clone, rt_sigaction, etc.) SHALL be allowed
- **AND** application executes without syscall denial errors

#### Scenario: Profile supports multi-architecture

- **WHEN** container runs on linux/amd64 or linux/arm64 architecture
- **THEN** seccomp profile SHALL include architecture-specific syscall mappings
- **AND** profile applies correctly on both architectures

### Requirement: AppArmor Profile for Java Applications

The project SHALL provide an AppArmor profile (`security/apparmor-java.txt`) that restricts filesystem access to JDK installation, workspace, and temporary directories.

#### Scenario: Profile allows JDK and application access

- **WHEN** container runs with `--security-opt apparmor=artagon-java`
- **THEN** Java process SHALL have read access to `/usr/lib/jvm/**` and `/workspace/**`
- **AND** Java process SHALL have read-write access to `/tmp/**`
- **AND** Java process SHALL have read access to `/dev/urandom`

#### Scenario: Profile denies sensitive path access

- **WHEN** process attempts to read `/etc/shadow`, `/root/**`, or `~/.ssh/**`
- **THEN** access SHALL be denied
- **AND** audit log SHALL record the denial

#### Scenario: Profile loads on host

- **WHEN** administrator loads profile with `apparmor_parser -r security/apparmor-java.txt`
- **THEN** profile SHALL load without errors
- **AND** profile SHALL appear in `/sys/kernel/security/apparmor/profiles`

### Requirement: Security Capability Labels

All container images SHALL include OCI labels documenting security capabilities and hardening features.

#### Scenario: Capability label indicates no capabilities

- **WHEN** image metadata is inspected
- **THEN** label `org.opencontainers.image.security.capabilities` SHALL equal "NONE"
- **AND** documentation SHALL clarify that runtime drops all capabilities

#### Scenario: Read-only rootfs label indicates recommendation

- **WHEN** image metadata is inspected
- **THEN** label `org.opencontainers.image.security.readonly-rootfs` SHALL equal "recommended"
- **AND** documentation SHALL provide guidance for mounting tmpfs volumes

#### Scenario: Seccomp label references profile

- **WHEN** image metadata is inspected
- **THEN** label `org.opencontainers.image.security.seccomp` SHALL reference `security/seccomp-java.json`
- **AND** label SHALL indicate profile location in repository

### Requirement: Vulnerability Scanning Thresholds

Container images SHALL fail builds if HIGH or CRITICAL severity CVEs are detected, with stricter thresholds than current implementation.

#### Scenario: Build fails on HIGH severity CVE

- **WHEN** Trivy or Grype scan detects HIGH severity CVE
- **THEN** CI build SHALL exit with non-zero status
- **AND** CVE details SHALL be logged to build output

#### Scenario: Build fails on CRITICAL severity CVE

- **WHEN** Trivy or Grype scan detects CRITICAL severity CVE
- **THEN** CI build SHALL exit with non-zero status
- **AND** CVE details SHALL be logged to build output
- **AND** nightly scan workflow SHALL create a GitHub issue for CRITICAL findings

#### Scenario: Build passes on MEDIUM or lower severity

- **WHEN** Trivy or Grype scan detects only MEDIUM, LOW, or NEGLIGIBLE severity CVEs
- **THEN** CI build SHALL continue successfully
- **AND** CVE summary SHALL be logged for informational purposes

### Requirement: CVE Response SLA

The project SHALL define and document Service Level Agreements for responding to and remediating container vulnerabilities.

#### Scenario: CRITICAL CVE response time

- **WHEN** CRITICAL severity CVE is discovered in published image
- **THEN** security team SHALL acknowledge within 24 hours
- **AND** patched image SHALL be published within 72 hours
- **AND** security advisory SHALL be posted to GitHub Security Advisories

#### Scenario: HIGH CVE response time

- **WHEN** HIGH severity CVE is discovered in published image
- **THEN** security team SHALL acknowledge within 48 hours
- **AND** patched image SHALL be published within 1 week
- **AND** issue SHALL be created tracking remediation

#### Scenario: Base image CVE outside project control

- **WHEN** CVE originates in base image (Chainguard, Distroless, UBI9) and no patched version available
- **THEN** issue SHALL document CVE and upstream status
- **AND** alternative mitigation strategies SHALL be provided if possible
- **AND** users SHALL be notified via release notes

### Requirement: SLSA Level 3 Provenance

Container images SHALL include SLSA Level 3 provenance attestations generated in isolated build environments with verifiable metadata.

#### Scenario: Provenance generated during build

- **WHEN** release workflow builds and publishes image
- **THEN** SLSA provenance SHALL be generated using `slsa-github-generator`
- **AND** provenance SHALL include builder identity, source repository, commit SHA, build parameters

#### Scenario: Provenance verification succeeds

- **WHEN** user runs `cosign verify-attestation --type slsaprovenance <image>`
- **THEN** verification SHALL succeed with valid signature
- **AND** provenance SHALL display builder identity as GitHub Actions
- **AND** provenance SHALL reference correct source repository and commit

#### Scenario: Provenance attestation attached to image

- **WHEN** image is pulled from registry
- **THEN** provenance attestation SHALL be retrievable via `cosign download attestation`
- **AND** attestation format SHALL be in-toto predicate with SLSA v1.0 schema

### Requirement: In-Toto Attestations for Build Steps

Build workflow SHALL generate in-toto attestations for critical build steps (JDK resolution, SBOM generation, vulnerability scanning) to provide detailed supply chain metadata.

#### Scenario: JDK resolution attestation

- **WHEN** JDK is downloaded and verified during build
- **THEN** attestation SHALL record JDK URL, SHA256 hash, download timestamp
- **AND** attestation SHALL be signed with Cosign keyless signature
- **AND** attestation SHALL reference builder identity

#### Scenario: SBOM generation attestation

- **WHEN** SBOM is generated with Syft
- **THEN** attestation SHALL record Syft version, SBOM format (CycloneDX), generation timestamp
- **AND** attestation SHALL include SBOM content hash
- **AND** attestation SHALL be attached to image via Cosign

#### Scenario: Vulnerability scan attestation

- **WHEN** image is scanned with Trivy or Grype
- **THEN** attestation SHALL record scanner version, scan timestamp, CVE count by severity
- **AND** attestation SHALL indicate pass/fail status
- **AND** attestation SHALL be stored in CI artifacts

