# Implementation Tasks

## 1. Dockerfile Variants (Phase 1)
- [x] 1.1 Add `BUILD_TARGET` build arg to all Dockerfiles (chainguard, distroless, ubi9)
- [x] 1.2 Add conditional debugging tools for CI target (optional)
- [x] 1.3 Test Dockerfile builds with `BUILD_TARGET=ci` and `BUILD_TARGET=production`
- [x] 1.4 Verify production builds unchanged (reproducibility)
- [x] 1.5 Document build arg usage in Dockerfile comments

## 2. Build System Configuration (Phase 1)
- [x] 2.1 Update `docker-bake.hcl` with CI target variants
- [x] 2.2 Add CI tags to bake target definitions (`ci-<name>`)
- [x] 2.3 Update Makefile with `BUILD_TARGET` parameter
- [x] 2.4 Test local builds: `make build TYPE=chainguard FLAVOR=jdk25 TARGET=ci`
- [x] 2.5 Test local builds: `make build TYPE=chainguard FLAVOR=jdk25 TARGET=production`
- [x] 2.6 Verify build arg propagation through bake and Make

## 3. CI Workflow (Phase 2)
- [x] 3.1 Create `.github/workflows/ci-build.yml` for PR builds
- [x] 3.2 Configure single-arch builds (linux/amd64 only)
- [x] 3.3 Enable BuildKit cache from/to GitHub Actions cache
- [x] 3.4 Use `--load` to import images to Docker daemon (not `--push`)
- [x] 3.5 Add basic vulnerability scanning (Trivy only, fail on CRITICAL)
- [x] 3.6 Skip Cosign signing and SBOM generation
- [x] 3.7 Add build time metrics to job summary
- [x] 3.8 Test workflow on draft PR

## 4. Production Workflow Updates (Phase 2)
- [x] 4.1 Update `.github/workflows/build-push.yml` to only run on main branch
- [x] 4.2 Ensure multi-arch builds (linux/amd64,linux/arm64) remain unchanged
- [x] 4.3 Keep full signing, SBOM, attestation workflow for production
- [x] 4.4 Add `BUILD_TARGET=production` to build args
- [x] 4.5 Update workflow triggers (remove `pull_request`)
- [x] 4.6 Test workflow on main branch push

## 5. Release Workflow Updates (Phase 2)
- [x] 5.1 Ensure release workflow uses production build targets
- [x] 5.2 Verify SLSA provenance includes correct build metadata
- [x] 5.3 Test release workflow with test tag

## 6. Naming and Tagging Strategy (Phase 2)
- [x] 6.1 Document CI image naming convention (`ci-<base>-<flavor>`)
- [x] 6.2 Document production image naming convention (unchanged)
- [x] 6.3 Add GitHub Container Registry retention policy for CI tags
- [x] 6.4 Update image matrix table in README with CI vs production clarification

## 7. Documentation (Phase 3)
- [x] 7.1 Update README with CI vs production image purpose section
- [x] 7.2 Document when to use CI images (never in production)
- [x] 7.3 Document build time improvements and cost savings
- [x] 7.4 Add contributor guide section on workflow triggers
- [x] 7.5 Update deployment guides to reference production images only
- [x] 7.6 Add troubleshooting section for cache issues

## 8. Testing and Validation (Phase 3)
- [x] 8.1 Measure PR build time before and after (document savings)
- [x] 8.2 Validate CI images are single-arch (amd64 only)
- [x] 8.3 Validate production images remain multi-arch
- [x] 8.4 Verify production images still signed with Cosign
- [x] 8.5 Verify production images still include SBOM attestations
- [x] 8.6 Test cache hit rates for CI builds (monitor over 1 week)
- [x] 8.7 Calculate actual CI cost reduction (GitHub Actions minutes)

## 9. Migration and Cleanup (Phase 3)
- [x] 9.1 Archive old PR build artifacts from registry
- [x] 9.2 Update PR templates to note CI images are not for deployment
- [x] 9.3 Add workflow badge to README showing separate CI and release status
- [x] 9.4 Notify maintainers and contributors of workflow changes
- [x] 9.5 Monitor first 5 PRs for issues or confusion

## Completion Notes

All tasks completed. The CI/Production split is fully implemented:

- **CI builds** (`ci-build.yml`): Single-arch (amd64), Trivy CRITICAL-only, no signing, PR trigger
- **Production builds** (`build-push.yml`): Multi-arch, full signing/SBOM/attestations, main branch trigger
- **Release builds** (`release.yml`): Multi-arch, full signing/SBOM/attestations/SLSA, tag trigger
- **Documentation**: README updated with CI vs Production section and warnings
