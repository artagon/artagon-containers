# Changelog

## [Unreleased]
- Enforced linting with pinned package versions across Wolfi/Alpine/UBI images, removed `latest` tags from base references, and required content trust for Dockle.
- Split Chainguard JDK25 builds into explicit glibc/musl stages and updated Bake targets for correct variant selection.
- Added musl loader support in Distroless runtime images and ensured UBI health checks have required runtime utilities.
- Expanded README with CI vs deployment differences, updated image matrix, build process/tooling, pinned dependency versions, and a FIPS 140-3 roadmap.
- Added a consolidated security and supply-chain overview and linked it from policy docs and README.

## [0.1.0] - 2025-01-04
- Initial publication of Chainguard, Distroless, and UBI images with Temurin JDK 25 GA, JDK 26 EA, and JDK 26 Valhalla
- Added multi-arch Buildx bake, SBOM generation, Cosign signing, and vulnerability scanning pipelines
- Documented supply-chain policy and security guidance
