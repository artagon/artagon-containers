# Implementation Tasks

## 1. Lock File Structure

- [x] 1.1 Create `versions/` directory
- [x] 1.2 Define lock file format (JSON with digest + packages)
- [x] 1.3 Create initial `versions/wolfi.lock` with current Wolfi digest and package versions
- [x] 1.4 Create initial `versions/alpine.lock` with current Alpine digest and package versions
- [x] 1.5 Create initial `versions/ubi9.lock` with current UBI9 digests and package info
- [x] 1.6 Create initial `versions/distroless.lock` with current Distroless digest

## 2. Version Detection Script

- [x] 2.1 Create `scripts/refresh-versions.sh` with subcommands: `detect`, `update`, `diff`
- [x] 2.2 Implement Wolfi version detection via `docker run ... apk info`
- [x] 2.3 Implement Alpine version detection via `docker run ... apk info`
- [x] 2.4 Implement UBI9 version detection via `docker run ... rpm -qa`
- [x] 2.5 Implement Distroless digest detection via `docker manifest inspect`
- [x] 2.6 Add `--check` mode to detect if updates are available without modifying files
- [x] 2.7 Add `--apply` mode to update lock files in place
- [ ] 2.8 Add retry logic for transient network failures

## 3. Bake Integration

- [x] 3.1 Add variable block to `docker-bake.hcl` for lock file values
- [x] 3.2 Create helper script or use `jq` to extract values from lock files (`scripts/lockfile-util.sh`)
- [x] 3.3 Update bake targets to use variables for digests
- [ ] 3.4 Verify bake builds work with variable injection

## 4. Dockerfile Updates

- [ ] 4.1 Update Chainguard Dockerfiles to use ARG for WOLFI_DIGEST from bake
- [ ] 4.2 Update Chainguard Dockerfiles to use ARG for ALPINE_DIGEST from bake
- [ ] 4.3 Update Distroless Dockerfiles to use ARG for digests from bake
- [ ] 4.4 Update UBI9 Dockerfiles to use ARG for digests from bake
- [ ] 4.5 Verify all Dockerfiles build correctly with injected values

## 5. GitHub Actions Workflow

- [x] 5.1 Create `.github/workflows/digest-refresh.yml`
- [x] 5.2 Configure weekly schedule trigger (Monday 06:00 UTC)
- [x] 5.3 Configure manual workflow_dispatch trigger with dry_run option
- [x] 5.4 Implement step to run `refresh-versions.sh --check`
- [x] 5.5 Implement step to run `refresh-versions.sh --apply` if updates found
- [x] 5.6 Implement step to create PR with updated lock files
- [x] 5.7 Include detailed PR description showing old vs new versions
- [x] 5.8 Add labels to PR (`dependencies`, `automated`)

## 6. Documentation

- [ ] 6.1 Document lock file format in `docs/lock-files.md`
- [ ] 6.2 Document manual refresh process
- [ ] 6.3 Update CLAUDE.md with lock file conventions
- [ ] 6.4 Add troubleshooting section for common issues

## 7. Validation

- [ ] 7.1 Run `openspec validate add-digest-refresh-workflow --strict`
- [ ] 7.2 Test workflow via manual dispatch
- [ ] 7.3 Verify PR creation works correctly
- [ ] 7.4 Verify CI builds pass with lock file values
- [ ] 7.5 Test rollback scenario (revert to previous lock file)
