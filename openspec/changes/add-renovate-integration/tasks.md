# Implementation Tasks

## 1. Renovate Configuration

- [x] 1.1 Create `renovate.json` with base configuration
- [x] 1.2 Enable `docker:pinDigests` preset
- [x] 1.3 Configure schedule (weekly Monday 06:00 UTC)
- [x] 1.4 Add package rules for base image grouping
- [ ] 1.5 Configure automerge settings (optional)

## 2. Dockerfile Updates

- [x] 2.1 Update `images/chainguard/Dockerfile.jdk25` with digest pin
- [x] 2.2 Update `images/chainguard/Dockerfile.jdk26ea` with digest pin
- [x] 2.3 Update `images/chainguard/Dockerfile.jdk26valhalla` with digest pin
- [x] 2.4 Update `images/distroless/Dockerfile.jre25` with digest pin
- [x] 2.5 Update `images/distroless/Dockerfile.jre26ea` with digest pin
- [x] 2.6 Update `images/distroless/Dockerfile.jre26valhalla` with digest pin
- [x] 2.7 Update `images/ubi9/Dockerfile.jdk25` with digest pin
- [x] 2.8 Update `images/ubi9/Dockerfile.jdk26ea` with digest pin
- [x] 2.9 Update `images/ubi9/Dockerfile.jdk26valhalla` with digest pin

## 3. Enable Renovate

- [ ] 3.1 Install Renovate GitHub App on repository
- [ ] 3.2 Verify Renovate creates onboarding PR
- [ ] 3.3 Review and merge onboarding PR
- [ ] 3.4 Verify dependency dashboard issue is created

## 4. Cleanup Custom Solution

- [ ] 4.1 Remove `.github/workflows/digest-refresh.yml`
- [ ] 4.2 Remove `scripts/refresh-versions.sh`
- [ ] 4.3 Remove `scripts/lockfile-util.sh`
- [ ] 4.4 Remove `versions/` directory and lock files
- [ ] 4.5 Simplify `docker-bake.hcl` (remove digest variables if not needed)

## 5. Documentation

- [ ] 5.1 Update CLAUDE.md with Renovate conventions
- [ ] 5.2 Document how to handle Renovate PRs
- [ ] 5.3 Document manual digest update process (if needed)

## 6. Validation

- [ ] 6.1 Verify Renovate detects all Dockerfiles
- [ ] 6.2 Verify Renovate creates PRs for outdated digests
- [ ] 6.3 Verify CI builds pass with Renovate-managed digests
- [ ] 6.4 Test manual workflow dispatch still works (if kept)
