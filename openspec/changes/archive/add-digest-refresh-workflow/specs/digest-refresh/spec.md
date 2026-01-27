# Digest Refresh Workflow Specification

## ADDED Requirements

### Requirement: Lock File Structure

The project SHALL maintain package version lock files in `versions/` directory that record:
- Base image digest (immutable reference)
- Package versions available in that base image
- Timestamp of last update
- Source registry information

Lock files SHALL use JSON format with the following structure:

```json
{
  "registry": "cgr.dev/chainguard/wolfi-base",
  "digest": "sha256:...",
  "updated": "2026-01-27T10:00:00Z",
  "packages": {
    "curl": "8.17.0-r0",
    "bash": "5.3-r3",
    "glibc": "2.42-r4"
  }
}
```

#### Scenario: Lock file exists for base image

- **GIVEN** a Dockerfile uses `cgr.dev/chainguard/wolfi-base`
- **WHEN** the build system reads the lock file
- **THEN** it SHALL use the digest from `versions/wolfi.lock`
- **AND** package versions SHALL be available for injection into Dockerfiles

#### Scenario: Lock file is missing

- **GIVEN** a lock file does not exist for a base image
- **WHEN** the build is attempted
- **THEN** the build SHALL fail with a clear error message
- **AND** instructions SHALL be provided to generate the lock file

### Requirement: Version Detection Script

The project SHALL provide `scripts/refresh-versions.sh` that:
- Detects available package versions from container images
- Supports multiple package managers (apk, rpm, dpkg)
- Compares current lock file with available versions
- Updates lock files atomically when changes are detected

The script SHALL support the following modes:
- `--check`: Report if updates are available (exit 0 if current, exit 1 if updates available)
- `--apply`: Update lock files with detected versions
- `--diff`: Show differences between current and available versions

#### Scenario: New base image digest available

- **WHEN** `refresh-versions.sh --check` is run
- **AND** a base image has a newer digest than recorded in the lock file
- **THEN** the script SHALL exit with code 1
- **AND** output SHALL indicate which images have updates

#### Scenario: Applying version updates

- **WHEN** `refresh-versions.sh --apply` is run
- **AND** updates are available
- **THEN** the script SHALL update all affected lock files
- **AND** each lock file SHALL have updated `digest`, `packages`, and `updated` fields
- **AND** the script SHALL output a summary of changes

#### Scenario: No updates available

- **WHEN** `refresh-versions.sh --check` is run
- **AND** all lock files are current
- **THEN** the script SHALL exit with code 0
- **AND** output SHALL indicate no updates found

### Requirement: Bake Integration

The `docker-bake.hcl` file SHALL define variables that are populated from lock files:
- `WOLFI_DIGEST` - Wolfi base image digest
- `ALPINE_DIGEST` - Alpine base image digest
- `UBI9_DIGEST` - UBI9 base image digest
- `UBI9_MINIMAL_DIGEST` - UBI9-minimal base image digest
- `DISTROLESS_DIGEST` - Distroless base image digest

Variables SHALL be injected via a helper script or CI environment.

#### Scenario: Building with bake variables

- **WHEN** `docker buildx bake` is invoked
- **THEN** digest variables SHALL be populated from lock files
- **AND** Dockerfiles SHALL receive correct digest values via ARG

### Requirement: Automated Refresh Workflow

The project SHALL provide `.github/workflows/digest-refresh.yml` that:
- Runs on a weekly schedule (configurable, default Sunday 02:00 UTC)
- Supports manual dispatch via `workflow_dispatch`
- Detects base image updates using the version detection script
- Creates a pull request when updates are found

The workflow SHALL NOT push directly to main; all changes require PR review.

#### Scenario: Weekly refresh finds updates

- **WHEN** the scheduled workflow runs
- **AND** base image updates are detected
- **THEN** the workflow SHALL create a branch `chore/refresh-base-images-YYYY-MM-DD`
- **AND** commit updated lock files to the branch
- **AND** create a pull request with title "chore(deps): refresh base image digests"
- **AND** the PR description SHALL list all changed images and versions

#### Scenario: Weekly refresh finds no updates

- **WHEN** the scheduled workflow runs
- **AND** no base image updates are detected
- **THEN** the workflow SHALL complete successfully
- **AND** no branch or PR SHALL be created
- **AND** the workflow summary SHALL indicate no updates found

#### Scenario: Manual refresh trigger

- **WHEN** a user triggers `workflow_dispatch`
- **THEN** the workflow SHALL run the same refresh logic
- **AND** create a PR if updates are found

### Requirement: PR Content

Pull requests created by the digest-refresh workflow SHALL include:
- Clear title indicating automated dependency update
- Table showing old vs new digests for each base image
- Table showing changed package versions (if applicable)
- Labels: `dependencies`, `automated`
- Link to workflow run for audit trail

#### Scenario: PR description format

- **WHEN** a refresh PR is created
- **THEN** the PR body SHALL contain:
  ```markdown
  ## Base Image Updates

  | Image | Old Digest | New Digest |
  |-------|-----------|------------|
  | wolfi-base | sha256:abc... | sha256:def... |

  ## Package Changes

  ### Wolfi
  | Package | Old Version | New Version |
  |---------|-------------|-------------|
  | glibc | 2.42-r3 | 2.42-r4 |

  ---
  Workflow run: [link]
  ```
