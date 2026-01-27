# CI and Production Container Images Split Proposal

## Why

Current workflow builds multi-architecture images (amd64+arm64) with full signing and SBOM generation for every PR, causing slow feedback cycles and high CI costs. Production deployments require these features, but CI/testing only needs fast, single-architecture validation. Separating build strategies can reduce PR build time by 50% and CI costs by 40-60% while maintaining production security standards.

## What Changes

This proposal introduces separate build configurations and workflows for CI testing versus production deployments:

- **CI images**: Fast single-arch (amd64) builds for PRs with basic validation, no signing/SBOM, ephemeral tags
- **Production images**: Multi-arch (amd64+arm64) builds for main/releases with full signing, SBOM, attestations
- **Build workflow split**: Separate GitHub Actions workflows (`ci-build.yml` for PRs, `build-push.yml` for main)
- **Dockerfile build args**: Conditional logic to enable/disable debugging tools based on build target
- **Naming convention**: CI images tagged with `ci-` prefix, production images use standard tags
- **Cache optimization**: Aggressive caching for CI builds, reproducible builds for production

**BREAKING CHANGES**:
- PR builds no longer push multi-arch images to registry (CI images are ephemeral, not suitable for deployment)
- CI image tags are unstable and may be overwritten (not for production use)
- Workflows must be split and updated with new triggers and conditions
- Build times and resource usage patterns change significantly

## Impact

**Affected specs**:
- `ci-images` (NEW) - Fast ephemeral builds for testing
- `production-images` (NEW) - Secure multi-arch releases
- `build-workflow` (NEW) - Conditional build logic and triggers

**Affected code**:
- Build system: `docker-bake.hcl`, `Makefile` (add CI target variants)
- Dockerfiles: `images/{chainguard,distroless,ubi9}/Dockerfile.*` (add conditional build args)
- Workflows: `.github/workflows/ci-build.yml` (NEW), `.github/workflows/build-push.yml` (MODIFIED)
- Documentation: `README.md`, deployment guides (clarify image purposes)

**Dependencies**:
- Docker Buildx cache backends (GitHub Actions cache, registry cache)
- GitHub Actions matrix strategy for conditional builds
- Updated CI/CD documentation for contributors

**Benefits**:
- 50% faster PR feedback (single-arch vs multi-arch builds)
- 40-60% reduction in CI costs (fewer builds, smaller artifacts)
- Faster developer iteration (load images locally for testing)
- Production images unchanged (no security trade-offs)

**Risks**:
- CI images not suitable for production (no signing, single arch)
- Developers may accidentally deploy CI images (need clear naming)
- Build logic complexity increases (separate paths for CI vs production)
- Testing coverage gaps if CI and production Dockerfiles diverge
- Cache misses increase storage costs if not managed

**Migration**:
- Update PR descriptions/templates to clarify CI images are not for deployment
- Add registry retention policy to clean up ephemeral CI tags
- Document CI vs production image purposes clearly
- Update contributor guide with new workflow expectations
