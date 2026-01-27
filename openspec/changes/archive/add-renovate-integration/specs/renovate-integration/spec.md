# Spec: Renovate Integration for Base Image Management

## Overview

Renovate automates dependency updates including Docker base image digests. This spec defines the configuration and behavior for Renovate in this repository.

## Requirements

### REQ-1: Digest Pinning Format

All Dockerfiles MUST use the tag+digest format for base images:

```dockerfile
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:abc123...
```

**Rationale**: This format maintains readability (tag visible) while ensuring reproducibility (digest pinned).

#### Scenarios

| ID | Scenario | Expected |
|----|----------|----------|
| 1.1 | Dockerfile has tag only | Renovate adds digest |
| 1.2 | Dockerfile has tag+digest | Renovate updates digest when upstream changes |
| 1.3 | Multi-stage build | All FROM lines are pinned |

### REQ-2: Update Schedule

Renovate MUST check for updates weekly on Monday at 06:00 UTC.

**Rationale**: Weekly updates balance security (timely patches) with stability (not too frequent).

#### Scenarios

| ID | Scenario | Expected |
|----|----------|----------|
| 2.1 | No updates available | No PR created |
| 2.2 | Updates available | PR created with all updates |
| 2.3 | Manual trigger | Updates checked immediately |

### REQ-3: PR Grouping

Base image updates SHOULD be grouped into a single PR per image family.

**Rationale**: Reduces PR noise while maintaining logical separation.

#### Groups

| Group | Images |
|-------|--------|
| chainguard | wolfi-base, alpine |
| distroless | base-debian12 |
| ubi9 | ubi9/ubi, ubi9-minimal |

#### Scenarios

| ID | Scenario | Expected |
|----|----------|----------|
| 3.1 | Wolfi and Alpine both updated | Single PR for Chainguard group |
| 3.2 | UBI9 updated | Separate PR for UBI9 group |
| 3.3 | All images updated | 3 PRs (one per group) |

### REQ-4: CI Integration

Renovate PRs MUST trigger the existing CI workflow for validation.

#### Scenarios

| ID | Scenario | Expected |
|----|----------|----------|
| 4.1 | Renovate PR created | CI builds all affected images |
| 4.2 | CI passes | PR ready for review |
| 4.3 | CI fails | PR blocked, requires investigation |

### REQ-5: Dependency Dashboard

Renovate MUST maintain a dependency dashboard issue for visibility.

**Rationale**: Provides single view of all pending updates and Renovate status.

#### Scenarios

| ID | Scenario | Expected |
|----|----------|----------|
| 5.1 | First run | Dashboard issue created |
| 5.2 | Updates pending | Dashboard shows pending PRs |
| 5.3 | All up to date | Dashboard shows green status |

## Configuration

### renovate.json

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    "docker:pinDigests",
    "schedule:weekly"
  ],
  "timezone": "UTC",
  "schedule": ["before 6am on monday"],
  "packageRules": [
    {
      "description": "Group Chainguard base images",
      "matchDatasources": ["docker"],
      "matchPackagePatterns": ["^cgr\\.dev/chainguard/", "^alpine$"],
      "groupName": "chainguard-base-images"
    },
    {
      "description": "Group Distroless base images",
      "matchDatasources": ["docker"],
      "matchPackagePatterns": ["^gcr\\.io/distroless/"],
      "groupName": "distroless-base-images"
    },
    {
      "description": "Group UBI9 base images",
      "matchDatasources": ["docker"],
      "matchPackagePatterns": ["^registry\\.access\\.redhat\\.com/ubi9"],
      "groupName": "ubi9-base-images"
    }
  ],
  "dependencyDashboard": true,
  "dependencyDashboardTitle": "Dependency Dashboard"
}
```

## Migration from Custom Solution

### Files to Remove

After Renovate is stable:

- `.github/workflows/digest-refresh.yml`
- `scripts/refresh-versions.sh`
- `scripts/lockfile-util.sh`
- `versions/*.lock`

### docker-bake.hcl Changes

The digest variables can be removed or kept for manual override:

```hcl
# Optional: Keep for manual override capability
variable "WOLFI_DIGEST" {
  default = ""  # Empty = use Dockerfile value
}
```

## Acceptance Criteria

- [ ] Renovate configuration file exists and is valid
- [ ] All Dockerfiles use tag+digest format
- [ ] Renovate creates PRs for outdated digests
- [ ] PRs trigger CI and pass validation
- [ ] Dependency dashboard issue is maintained
- [ ] Custom solution is removed or deprecated
