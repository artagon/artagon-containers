# Proposal: Publish CI Images on Main Merge

## Context
Currently, `ci-` prefixed images (single-arch, with debug tools) are ephemeral and built only during PR validation. They are never pushed to the registry. However, downstream Artagon projects (e.g., Java applications) require these "fat" images for their own CI pipelines (e.g., for integration testing or build environments requiring `curl`/`netcat`).

## Goal
Publish `ci-` prefixed images to the container registry (GHCR) when changes are merged to the `main` branch, alongside the production images.

## Strategy
1.  **Modify Deployment Workflow:** Update `.github/workflows/build-push.yml` to include `ci-*` targets in the build matrix.
2.  **Full Security Compliance:** Treat these published CI images as first-class artifacts. They will be scanned, signed, and verified with SBOM attestations, just like production images. This ensures the entire software supply chain—including the build tools—is secured.
3.  **Retention:** These images will share the lifecycle policy of other images in the registry.

## Benefits
*   **Downstream Usage:** Other projects can simply `FROM ghcr.io/artagon/artagon-containers:ci-chainguard-jdk25` in their CI workflows.
*   **Traceability:** CI tooling is versioned, signed, and attested.

## Trade-offs
*   **Registry Storage:** Increases the number of stored tags (doubles the tag count).
*   **Build Time:** The `main` branch build duration will increase slightly, but since it runs in parallel (matrix strategy) and CI images are single-arch, the impact is minimal.
