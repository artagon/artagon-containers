# Build Workflow Specification

## ADDED Requirements

### Requirement: Conditional Build Target Selection

Build workflows SHALL select appropriate build target (CI or production) based on triggering event and branch to optimize for speed or security.

#### Scenario: PR builds use CI target

- **WHEN** workflow is triggered by pull_request event
- **THEN** workflow SHALL set `BUILD_TARGET=ci`
- **AND** workflow SHALL build single-arch images
- **AND** workflow SHALL skip signing and SBOM generation

#### Scenario: Main branch builds use production target

- **WHEN** workflow is triggered by push to main branch
- **THEN** workflow SHALL set `BUILD_TARGET=production`
- **AND** workflow SHALL build multi-arch images
- **AND** workflow SHALL include signing and SBOM generation

#### Scenario: Release builds use production target

- **WHEN** workflow is triggered by release tag creation
- **THEN** workflow SHALL set `BUILD_TARGET=production`
- **AND** workflow SHALL include full attestation workflow

### Requirement: Workflow Separation by Purpose

Build system SHALL maintain separate workflow files for CI builds (.github/workflows/ci-build.yml) and production builds (.github/workflows/build-push.yml).

#### Scenario: CI workflow handles PRs only

- **WHEN** ci-build.yml workflow is defined
- **THEN** workflow triggers SHALL include only `pull_request` events
- **AND** workflow SHALL NOT trigger on main branch pushes
- **AND** workflow SHALL NOT trigger on release tags

#### Scenario: Production workflow handles main and releases

- **WHEN** build-push.yml workflow is defined
- **THEN** workflow triggers SHALL include `push` to main branch
- **AND** workflow triggers SHALL include release tag creation
- **AND** workflow SHALL NOT trigger on pull_request events

#### Scenario: Workflows do not conflict

- **WHEN** both CI and production workflows exist
- **THEN** workflows SHALL have mutually exclusive triggers
- **AND** workflows SHALL NOT execute simultaneously for same commit
- **AND** GitHub Actions UI SHALL clearly distinguish workflow purposes

### Requirement: Build Matrix Strategy

Workflows SHALL use GitHub Actions matrix strategy to build multiple image variants in parallel while respecting resource constraints.

#### Scenario: CI workflow builds subset of targets

- **WHEN** CI workflow executes
- **THEN** workflow matrix SHALL include subset of image variants optimized for fast feedback (e.g., one per base type)
- **AND** matrix SHALL prioritize fast feedback over complete coverage
- **AND** full coverage SHALL be validated in main branch builds

#### Scenario: Production workflow builds all targets

- **WHEN** production workflow executes
- **THEN** workflow matrix SHALL include all 15 image targets
- **AND** matrix jobs SHALL execute in parallel
- **AND** workflow SHALL complete within 60-minute timeout

#### Scenario: Matrix failure handling

- **WHEN** one matrix job fails
- **THEN** workflow SHALL continue executing remaining jobs (fail-fast: false)
- **AND** workflow overall status SHALL reflect any job failures
- **AND** partial build results SHALL be available for debugging

### Requirement: Cache Strategy Differentiation

CI and production workflows SHALL use different cache strategies optimized for their respective goals (speed vs reproducibility).

#### Scenario: CI workflow uses GHA cache

- **WHEN** CI workflow builds image
- **THEN** workflow SHALL use `cache-from=type=gha` and `cache-to=type=gha,mode=max`
- **AND** cache scope SHALL be per-target
- **AND** cache SHALL prioritize speed over storage efficiency

#### Scenario: Production workflow uses registry cache

- **WHEN** production workflow builds image
- **THEN** workflow SHALL support `cache-from=type=registry` option for reproducibility
- **AND** workflow SHALL support GitHub Actions cache as fallback option
- **AND** cache strategy SHALL support cross-runner reproducible builds

#### Scenario: Cache does not affect image digest

- **WHEN** production build uses cache
- **THEN** resulting image digest SHALL be identical to cache-less build for same source
- **AND** cache SHALL only affect build time, not image content

### Requirement: Artifact Publishing Strategy

Workflows SHALL publish build artifacts (images, SBOMs, attestations) to appropriate destinations based on build purpose.

#### Scenario: CI builds do not publish to registry

- **WHEN** CI workflow completes
- **THEN** images SHALL remain in local Docker daemon only
- **AND** images SHALL NOT be pushed to container registry
- **AND** workflow SHALL use `--load` flag instead of `--push`

#### Scenario: Production builds publish to GHCR

- **WHEN** production workflow completes successfully
- **THEN** images SHALL be pushed to GitHub Container Registry
- **AND** signatures and attestations SHALL be attached to images
- **AND** images SHALL be publicly accessible

#### Scenario: SBOM artifacts stored as build artifacts

- **WHEN** production workflow generates SBOMs
- **THEN** SBOMs SHALL be uploaded as GitHub Actions artifacts
- **AND** SBOMs SHALL be retained for 90 days
- **AND** SBOMs SHALL be included in release assets

### Requirement: Workflow Timeout and Resource Limits

Workflows SHALL enforce timeout limits and resource constraints to prevent runaway builds and manage costs.

#### Scenario: CI workflow has tight timeout

- **WHEN** CI workflow is defined
- **THEN** workflow SHALL have timeout-minutes of 30 or less
- **AND** timeout SHALL ensure fast failure for stuck builds
- **AND** timeout SHALL be sufficient for single-arch builds with cache

#### Scenario: Production workflow has generous timeout

- **WHEN** production workflow is defined
- **THEN** workflow SHALL have timeout-minutes of 60
- **AND** timeout SHALL accommodate multi-arch builds and QEMU emulation
- **AND** timeout SHALL include buffer for signing and attestation steps

#### Scenario: Build cancellation on new commits

- **WHEN** new commit pushed to PR with running CI build
- **THEN** previous CI workflow run SHALL be automatically cancelled
- **AND** only latest commit SHALL be built
- **AND** resources SHALL be freed for new build

### Requirement: Build Status Reporting

Workflows SHALL report build status to pull requests and commit statuses to provide clear feedback to contributors.

#### Scenario: CI build reports to PR checks

- **WHEN** CI workflow executes for pull request
- **THEN** workflow status SHALL appear in PR checks section
- **AND** status SHALL indicate pass/fail for each matrix job
- **AND** check SHALL block merge if required status checks configured

#### Scenario: Production build updates commit status

- **WHEN** production workflow executes for main branch commit
- **THEN** workflow status SHALL update commit status badge
- **AND** status SHALL be visible on commit history page

#### Scenario: Build summary includes key metrics

- **WHEN** workflow completes
- **THEN** workflow SHALL write summary to $GITHUB_STEP_SUMMARY
- **AND** summary SHALL include: build target, image tags, scan results, timing
- **AND** summary SHALL be viewable in GitHub Actions UI

### Requirement: Error Handling and Debugging

Workflows SHALL provide clear error messages and debugging context when builds fail to facilitate rapid issue resolution.

#### Scenario: Build failure includes logs

- **WHEN** build step fails
- **THEN** workflow SHALL output full build logs to job output
- **AND** logs SHALL include error messages and stack traces
- **AND** logs SHALL be searchable in GitHub Actions UI

#### Scenario: Scan failure includes CVE details

- **WHEN** vulnerability scan fails build
- **THEN** workflow SHALL log CVE IDs, severity, affected packages
- **AND** workflow SHALL provide remediation guidance if available
- **AND** failure SHALL reference relevant documentation

#### Scenario: Workflow includes debug annotations

- **WHEN** workflow executes with debugging enabled
- **THEN** workflow SHALL output key variables and decisions
- **AND** workflow SHALL annotate steps with timing information
- **AND** annotations SHALL assist in identifying bottlenecks

### Requirement: Workflow Maintenance and Updates

Workflows SHALL be maintainable through clear structure, comments, and version pinning for external actions.

#### Scenario: External actions are pinned by SHA

- **WHEN** workflow uses external GitHub Action
- **THEN** action reference SHALL include full commit SHA (e.g., `actions/checkout@abc123...`)
- **AND** action reference SHALL include version comment (e.g., `# v4.2.2`)
- **AND** Dependabot SHALL monitor for action updates

#### Scenario: Workflow includes inline documentation

- **WHEN** workflow file is reviewed
- **THEN** workflow SHALL include comments explaining complex logic
- **AND** workflow SHALL document required secrets and permissions
- **AND** workflow SHALL reference related documentation

#### Scenario: Workflow changes validated before merge

- **WHEN** workflow file is modified in PR
- **THEN** PR SHALL trigger workflow to validate changes
- **AND** workflow syntax SHALL be validated by GitHub Actions
- **AND** breaking changes SHALL be tested in draft PR first

### Requirement: Cost Monitoring and Optimization

Workflows SHALL be designed to minimize GitHub Actions usage costs while maintaining build quality.

#### Scenario: CI builds minimize runner minutes

- **WHEN** CI workflow design is evaluated
- **THEN** workflow SHALL prioritize strategies that reduce runner time:
  - Single-arch builds
  - Aggressive caching
  - Parallel matrix execution
  - Early failure detection

#### Scenario: Production builds optimize for quality

- **WHEN** production workflow design is evaluated
- **THEN** workflow SHALL prioritize build quality over speed:
  - Complete architecture coverage
  - Comprehensive security scanning
  - Full attestation workflow
- **AND** optimizations SHALL not compromise security

#### Scenario: Build metrics enable cost analysis

- **WHEN** workflows complete
- **THEN** metrics SHALL enable cost analysis:
  - Total runner minutes per workflow
  - Cache hit rates
  - Build time per target
- **AND** metrics SHALL inform future optimization decisions
