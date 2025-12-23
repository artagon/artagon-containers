# container-runtime Specification

## Purpose
TBD - created by archiving change add-container-hardening. Update Purpose after archive.
## Requirements
### Requirement: Read-Only Root Filesystem Support

All container images SHALL support execution with read-only root filesystem when appropriate writable volumes are mounted.

#### Scenario: Container runs with read-only rootfs

- **WHEN** container is started with `docker run --read-only --tmpfs /tmp <image>`
- **THEN** container SHALL start successfully
- **AND** JVM SHALL initialize and execute without errors
- **AND** JVM SHALL write temporary files to `/tmp` only

#### Scenario: Kubernetes deployment with read-only rootfs

- **WHEN** Kubernetes pod spec includes `securityContext.readOnlyRootFilesystem: true` and tmpfs volume mounted at `/tmp`
- **THEN** pod SHALL reach Ready state
- **AND** Java application SHALL function normally
- **AND** health checks SHALL pass

#### Scenario: Application writing outside /tmp fails gracefully

- **WHEN** application attempts to write to `/workspace` or other paths with read-only rootfs enabled
- **THEN** write operation SHALL fail with permission denied error
- **AND** error message SHALL indicate read-only filesystem
- **AND** documentation SHALL guide users to mount writable volumes

### Requirement: Health Check Configuration

All Dockerfiles SHALL include HEALTHCHECK instructions that verify JVM functionality for container orchestration integration. Distroless images SHALL use exec-form `java -XshowSettings:properties -version` (no shell available). Chainguard and UBI images SHALL use `/usr/local/bin/health-check.sh`, which falls back to the same JVM settings check when HTTP endpoints are unavailable.

#### Scenario: Health check passes for running JVM

- **WHEN** container is running and JVM is functional
- **THEN** health check SHALL execute `/usr/local/bin/health-check.sh` or `java -XshowSettings:properties -version` (Distroless)
- **AND** health check SHALL complete within 3 second timeout
- **AND** container status SHALL report "healthy"

#### Scenario: Health check fails for broken JVM

- **WHEN** JVM binary is missing or unexecutable
- **THEN** health check SHALL fail after 3 retries
- **AND** container status SHALL report "unhealthy"
- **AND** Kubernetes/Docker Compose SHALL restart container automatically

#### Scenario: Health check respects startup period

- **WHEN** container is starting and JVM is initializing
- **THEN** health check failures during 5-second start period SHALL NOT mark container unhealthy
- **AND** health check SHALL begin regular intervals after start period
- **AND** slow-starting applications SHALL have time to initialize

#### Scenario: Custom health checks override default

- **WHEN** application provides custom Dockerfile with application-specific HEALTHCHECK
- **THEN** custom HEALTHCHECK SHALL replace baseline version check
- **AND** documentation SHALL provide examples of HTTP-based health checks

### Requirement: Non-Root User Enforcement

All container images SHALL run as non-root user (UID 65532, GID 65532) and SHALL NOT permit escalation to root privileges.

#### Scenario: Container runs as non-root user

- **WHEN** container is inspected for running processes
- **THEN** Java process SHALL run as UID 65532 (user "runner")
- **AND** Java process SHALL run as GID 65532 (group "runner")
- **AND** process SHALL NOT have root privileges

#### Scenario: Container cannot escalate to root

- **WHEN** process attempts to escalate privileges or execute setuid binaries
- **THEN** operation SHALL be blocked
- **AND** audit log SHALL record privilege escalation attempt
- **AND** container SHALL continue running as non-root

#### Scenario: Kubernetes enforces non-root policy

- **WHEN** Kubernetes pod spec includes `securityContext.runAsNonRoot: true`
- **THEN** pod SHALL admit successfully
- **AND** Kubernetes SHALL verify container runs as non-root user
- **AND** pod SHALL NOT be rejected by admission controller

### Requirement: Linux Capabilities Drop

Container images SHALL document that all Linux capabilities should be dropped at runtime and SHALL function correctly without any capabilities.

#### Scenario: Container runs without capabilities

- **WHEN** container is started with `docker run --cap-drop=ALL <image>`
- **THEN** container SHALL start successfully
- **AND** JVM SHALL function normally without requiring privileged operations
- **AND** Java application SHALL execute without capability-related errors

#### Scenario: Kubernetes drops all capabilities

- **WHEN** Kubernetes pod spec includes `securityContext.capabilities.drop: [ALL]`
- **THEN** pod SHALL start successfully
- **AND** Java process SHALL operate without kernel capabilities
- **AND** security audit SHALL confirm zero capabilities assigned

#### Scenario: Documentation clarifies capability requirements

- **WHEN** user reviews image documentation
- **THEN** OCI label `org.opencontainers.image.security.capabilities` SHALL indicate "NONE"
- **AND** documentation SHALL state images require no capabilities
- **AND** deployment examples SHALL include capability drop configurations

### Requirement: Filesystem Permissions and Ownership

Container images SHALL configure filesystem permissions and ownership to prevent unauthorized access and follow principle of least privilege.

#### Scenario: JDK installation is read-only

- **WHEN** container filesystem is inspected
- **THEN** JDK directory (`/usr/lib/jvm/*`) SHALL have read-only permissions for non-root users
- **AND** JDK binaries SHALL be owned by root user
- **AND** non-root user SHALL NOT be able to modify JDK installation

#### Scenario: Workspace directory is accessible

- **WHEN** container starts with user UID 65532
- **THEN** `/workspace` directory SHALL be accessible for reading
- **AND** user SHALL be able to read application JARs and resources
- **AND** user SHALL have appropriate permissions based on volume mount configuration

#### Scenario: Temporary directory is writable

- **WHEN** JVM requires temporary file storage
- **THEN** `/tmp` directory SHALL be writable by user UID 65532
- **AND** JVM SHALL successfully create temporary files for class loading and native libraries
- **AND** temporary files SHALL be isolated from other container users

### Requirement: No New Privileges Security Option

Container images SHALL be compatible with `no-new-privileges` security option to prevent privilege escalation via setuid binaries.

#### Scenario: Container runs with no-new-privileges

- **WHEN** container is started with `docker run --security-opt no-new-privileges <image>`
- **THEN** container SHALL start successfully
- **AND** processes SHALL NOT be able to gain additional privileges
- **AND** setuid/setgid bits SHALL be ignored

#### Scenario: Kubernetes enforces no new privileges

- **WHEN** Kubernetes pod spec includes `securityContext.allowPrivilegeEscalation: false`
- **THEN** pod SHALL start successfully
- **AND** Kubernetes SHALL enforce no-new-privileges at kernel level
- **AND** security audit SHALL confirm privilege escalation prevention

