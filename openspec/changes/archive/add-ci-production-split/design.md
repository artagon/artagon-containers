# CI and Production Images Split Design

## Context

Multi-architecture container builds are essential for production deployments supporting diverse cloud infrastructure (AWS Graviton, GCP Tau, Azure Ampere). However, PR testing only requires functional validation on a single architecture. Building arm64 images on every PR commit wastes CI resources through QEMU emulation overhead and increases feedback latency for contributors.

**Stakeholders**:
- Contributors needing fast PR feedback (target: <10 minute builds)
- Finance/operations teams managing GitHub Actions costs
- Security teams requiring signed, attested production images
- Platform engineers deploying to multi-arch Kubernetes clusters

**Constraints**:
- Production images must maintain current security posture (signing, SBOM, multi-arch)
- CI builds must validate functionality equivalently to production builds
- Workflows must remain maintainable (minimize duplication)
- Image naming must prevent accidental deployment of CI images to production
- Cache strategy must balance speed vs storage costs

## Goals / Non-Goals

**Goals**:
- Reduce PR build time from ~20 minutes to <10 minutes (50% improvement)
- Reduce CI costs by 40-60% through single-arch builds and disabled signing
- Maintain identical Dockerfile sources for CI and production (conditional logic only)
- Preserve production image quality, security, and multi-arch support
- Enable local image loading for rapid developer testing (`docker load`)

**Non-Goals**:
- Building separate CI-specific Dockerfiles (increases maintenance)
- Removing multi-arch support for production images
- Reducing security scanning depth for CI builds (keep HIGH/CRITICAL gates)
- Publishing CI images for external consumption (ephemeral only)
- Supporting CI images for production deployment (explicitly not supported)

## Decisions

### Decision 1: Single Dockerfile with Build Args

**Choice**: Use `BUILD_TARGET` build arg to conditionally include debugging tools, not separate Dockerfiles

**Rationale**:
- Single source of truth reduces drift between CI and production
- Build arg allows conditional RUN instructions: `RUN if [ "$BUILD_TARGET" = "ci" ]; then ...; fi`
- Minimal impact on Dockerfile complexity (1-2 conditional blocks)
- Production builds unaffected when `BUILD_TARGET=production` or unset

**Alternatives considered**:
- Separate Dockerfiles (e.g., `Dockerfile.ci`): Doubles maintenance, high drift risk
- Multi-stage builds with different final stages: Increases layer count, cache complexity
- Post-build modification: Violates reproducibility, adds tooling complexity

**Implementation**:
```dockerfile
ARG BUILD_TARGET=production

# Optional: Add debugging tools for CI
RUN if [ "$BUILD_TARGET" = "ci" ]; then \
      apk add --no-cache curl netcat bind-tools; \
    fi
```

**Testing strategy**:
- Build with `--build-arg BUILD_TARGET=ci` and verify debugging tools present
- Build with `--build-arg BUILD_TARGET=production` and verify tools absent
- Verify production image size unchanged

### Decision 2: Separate Workflows for CI vs Production

**Choice**: Create `ci-build.yml` for PRs, restrict `build-push.yml` to main branch only

**Rationale**:
- Clear separation of concerns: CI workflow optimizes for speed, production for security
- Different triggers prevent accidental cross-contamination
- Easier to tune each workflow independently (caching, scanning, signing)
- GitHub Actions UI clearly shows distinct pipeline purposes

**Alternatives considered**:
- Single workflow with conditional logic: Too complex, hard to read, error-prone
- Reusable workflow called from both: Shared logic tight-coupled, limits flexibility
- Manual workflow dispatch: Doesn't scale for frequent PRs

**Implementation**:

`ci-build.yml` (PR builds):
```yaml
on:
  pull_request:

jobs:
  build:
    strategy:
      matrix:
        target: [chainguard-jdk25, distroless-jre25, ubi9-jdk25]
    steps:
      - name: Build single-arch image
        run: |
          docker buildx bake ${{ matrix.target }} \
            --set *.args.BUILD_TARGET=ci \
            --set *.platform=linux/amd64 \
            --set *.cache-from=type=gha \
            --set *.cache-to=type=gha,mode=max \
            --load

      - name: Basic scan (Trivy only)
        run: trivy image --exit-code 1 --severity CRITICAL local:${{ matrix.target }}
```

`build-push.yml` (main branch):
```yaml
on:
  push:
    branches: [main]

jobs:
  build:
    strategy:
      matrix:
        target: [chainguard-jdk25, ...] # All 15 targets
    steps:
      - name: Build multi-arch image
        run: |
          docker buildx bake ${{ matrix.target }} \
            --set *.args.BUILD_TARGET=production \
            --push

      - name: Full scan (Trivy + Grype)
        run: |
          trivy image --exit-code 1 --severity HIGH,CRITICAL $REGISTRY:${{ matrix.target }}
          grype $REGISTRY:${{ matrix.target }}

      - name: Sign and attest
        run: cosign sign --yes $REGISTRY@${{ needs.build.outputs.digest }}
```

**Testing strategy**:
- Create test PR and verify `ci-build.yml` triggers
- Push to main and verify `build-push.yml` triggers
- Verify workflows do not cross-trigger

### Decision 3: GitHub Actions Cache for CI Builds

**Choice**: Use `cache-from=type=gha` and `cache-to=type=gha,mode=max` for CI builds

**Rationale**:
- GitHub Actions cache is free (10GB limit per repository)
- Native integration with Buildx (no configuration needed)
- Fast cache access within same GitHub runner environment
- `mode=max` caches all layers for maximum hit rate

**Alternatives considered**:
- Registry cache (`type=registry`): Costs GHCR storage, slower pulls
- Inline cache: Bloats image size, less effective for multi-stage builds
- No cache: Unacceptable build times (15-20 minutes)

**Implementation**:
```yaml
- name: Build with cache
  run: |
    docker buildx bake ${{ matrix.target }} \
      --set *.cache-from=type=gha,scope=${{ matrix.target }} \
      --set *.cache-to=type=gha,mode=max,scope=${{ matrix.target }} \
      --load
```

**Cache scope strategy**:
- Per-target scopes prevent cache pollution between image variants
- 10GB limit sufficient for ~15 targets × ~200MB cache layers
- GitHub auto-evicts least recently used caches

**Testing strategy**:
- First PR build (cold cache): measure build time
- Second PR build (warm cache): verify >80% cache hit rate
- Monitor cache size: `gh api repos/artagon/artagon-containers/actions/caches`

### Decision 4: Image Naming Convention

**Choice**: CI images tagged as `ci-<base>-<flavor>`, production images unchanged

**Rationale**:
- `ci-` prefix clearly indicates ephemeral, non-production status
- Prevents accidental production deployment (manifest errors obvious)
- Production tags remain stable for existing users
- Simple to document and understand

**Alternatives considered**:
- Suffix (`-ci`): Less visible, can be missed in deploy scripts
- Separate registry namespace: Overkill, complicates permissions
- Short-lived tags (timestamp): Harder to reference in PR checks

**Implementation**:
```hcl
# docker-bake.hcl
target "ci-chainguard-jdk25" {
  inherits = ["common"]
  dockerfile = "images/chainguard/Dockerfile.jdk25"
  args = { BUILD_TARGET = "ci" }
  platforms = ["linux/amd64"]
  tags = ["${REGISTRY}:ci-chainguard-jdk25"]
}
```

**Registry retention**:
- Configure GitHub Package retention to delete untagged manifests after 7 days
- CI tags can be overwritten (unstable)
- Production tags immutable (never overwrite)

**Testing strategy**:
- Attempt to deploy CI image to Kubernetes, verify manifest references cause confusion
- Document clear warning in image labels

### Decision 5: Reduced Scanning for CI Builds

**Choice**: Scan CI images with Trivy only (not Grype), fail on CRITICAL only (not HIGH)

**Rationale**:
- CI builds validate functionality, not production readiness
- CRITICAL CVEs indicate immediate risk (remote code execution, privilege escalation)
- HIGH CVEs addressed in main branch builds before production
- Single scanner (Trivy) reduces scan time by 50%

**Alternatives considered**:
- No scanning: Unacceptable, misses critical vulnerabilities in dependencies
- Full scanning (HIGH+CRITICAL, Trivy+Grype): No time savings, defeats purpose
- Separate "fast scan" profile: Added complexity

**Implementation**:
```yaml
- name: Scan CI image
  run: trivy image --exit-code 1 --severity CRITICAL local:ci-${{ matrix.target }}
```

**Security trade-off**:
- CI images never reach production (ephemeral)
- HIGH CVEs caught in main branch builds
- Reduced PR feedback latency outweighs risk

**Testing strategy**:
- Inject test HIGH CVE in CI build, verify build succeeds
- Inject test CRITICAL CVE in CI build, verify build fails
- Validate main branch builds still fail on HIGH CVEs

### Decision 6: Skip Signing and SBOM for CI Builds

**Choice**: CI builds skip Cosign signing, Syft SBOM generation, and attestations

**Rationale**:
- Signing adds ~30 seconds per image (keyless OIDC flow)
- SBOM generation adds ~20 seconds per image
- CI images are ephemeral, never deployed to production
- Security features only valuable for production releases

**Alternatives considered**:
- Sign CI images: Wasted time, no security value (images not deployed)
- Generate SBOMs but don't sign: Partial value, still slows builds

**Implementation**:
```yaml
# ci-build.yml (no signing or SBOM steps)

# build-push.yml (full security workflow)
- name: Generate SBOM
  run: syft $REGISTRY:${{ matrix.target }} -o cyclonedx-json > sbom.json

- name: Sign and attest
  run: |
    cosign sign --yes $REGISTRY@${{ needs.build.outputs.digest }}
    cosign attest --yes --predicate sbom.json --type cyclonedx $REGISTRY@${{ needs.build.outputs.digest }}
```

**Testing strategy**:
- Verify CI image has no Cosign signatures: `cosign verify <ci-image>` fails
- Verify production image has signatures: `cosign verify <prod-image>` succeeds

## Risks / Trade-offs

### Risk 1: CI and Production Dockerfile Drift

**Risk**: Conditional build logic causes CI and production images to diverge unintentionally

**Likelihood**: Medium (developers may add CI-specific changes without testing production)

**Impact**: High (production builds may fail or behave differently than CI builds)

**Mitigation**:
- Minimize conditional logic (only debugging tools, not core functionality)
- CI workflow tests with `BUILD_TARGET=production` periodically (weekly)
- Code review guidelines require testing both build targets for Dockerfile changes
- Automated tests validate image behavior is identical (Java version, JAVA_HOME, etc.)

### Risk 2: Cache Storage Costs

**Risk**: Aggressive caching consumes GitHub Actions cache storage (10GB free limit)

**Likelihood**: Low (15 targets × ~200MB/target = ~3GB)

**Impact**: Medium (cache evictions slow down builds)

**Mitigation**:
- Per-target cache scopes prevent unbounded growth
- Monitor cache usage: `gh api repos/.../actions/caches --jq '.total_size_in_bytes'`
- Configure cache retention policy (evict after 7 days)
- Fall back to registry cache if GitHub cache exhausted

### Risk 3: Accidental CI Image Deployment

**Risk**: Users deploy CI images to production due to confusion or copy-paste errors

**Likelihood**: Medium (clear naming reduces risk, but human error possible)

**Impact**: High (single-arch image in multi-arch cluster causes failures)

**Mitigation**:
- `ci-` prefix makes purpose obvious
- Add OCI label: `org.opencontainers.image.ci=true`
- Documentation clearly states CI images not for production
- Example manifests reference production images only
- Consider admission controller webhook rejecting `ci-` images (future)

### Risk 4: CI Build Coverage Gaps

**Risk**: Single-arch CI builds miss arm64-specific issues (e.g., architecture-dependent JVM bugs)

**Likelihood**: Low (JVM bytecode platform-independent, JIT issues rare)

**Impact**: Medium (arm64 production deployments fail)

**Mitigation**:
- Main branch builds still validate both architectures
- Arm64-specific issues caught before release
- JDK resolution script validates binaries for both architectures
- Monthly test runs on arm64 hardware (GitHub Actions arm64 runners)

## Migration Plan

### Phase 1: Dockerfile and Build System (Non-Breaking)

1. Add `BUILD_TARGET` build arg to all Dockerfiles (default: `production`)
2. Update `docker-bake.hcl` with CI target variants
3. Test local builds with both targets
4. Document build arg usage

**Rollback**: Remove build arg, restore original Dockerfiles

### Phase 2: CI Workflow (Non-Breaking for Main)

1. Create `ci-build.yml` for PR builds
2. Keep `build-push.yml` running on both `pull_request` and `push` (main)
3. Monitor CI build times and cache hit rates for 1 week
4. Collect feedback from contributors

**Rollback**: Delete `ci-build.yml`, workflows unchanged

### Phase 3: Production Workflow Restriction (Breaking for PR Images)

1. Remove `pull_request` trigger from `build-push.yml`
2. Update workflow to only run on `push` to main
3. Announce change in PR template and CONTRIBUTING.md
4. Monitor for issues or confusion

**Rollback**: Re-add `pull_request` trigger to `build-push.yml`

### Phase 4: Optimization and Cleanup

1. Add registry retention policy for CI tags
2. Tune cache scopes and eviction
3. Document cost savings and performance improvements

**Rollback**: N/A (cleanup only)

### User Migration Steps

No user migration required. Changes affect CI/CD only. Production images unchanged.

**For contributors**:
1. Review new CI workflow documentation
2. Understand CI images are ephemeral, not for deployment
3. Test PR builds complete faster (<10 minutes)

## Open Questions

1. **Should CI builds ever push to registry?**
   - **Proposed Answer**: No. Use `--load` to keep images local. Reduces registry storage costs.

2. **Should we support multi-arch CI builds on-demand?**
   - **Proposed Answer**: Add workflow_dispatch input for manual multi-arch CI builds (rare use case)

3. **Should CI images include debugging tools by default?**
   - **Proposed Answer**: Yes, but minimal (curl, netcat). Document how to customize for specific needs.

4. **How to handle cache eviction issues?**
   - **Proposed Answer**: Monitor cache hit rates, switch to registry cache if GitHub cache insufficient

5. **Should we support CI images for integration testing?**
   - **Proposed Answer**: Defer to future proposal. CI images sufficient for unit/functional tests, integration tests may need production parity.
