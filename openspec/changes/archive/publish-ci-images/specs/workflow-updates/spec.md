# Spec: Publish CI Images Workflow

## Component: GitHub Actions Workflow (`build-push.yml`)

The `build-push.yml` workflow orchestrates the build, scan, sign, and push process for the `main` branch.

### Modification Details

1.  **Matrix Expansion:**
    The `strategy.matrix.include` list must be expanded to include all 15 `ci-` prefixed targets.
    
    **New Targets to Add:**
    *   `ci-chainguard-jdk25`
    *   `ci-chainguard-jdk25-musl`
    *   `ci-chainguard-jdk26ea`
    *   `ci-chainguard-jdk26ea-musl`
    *   `ci-chainguard-jdk26valhalla`
    *   `ci-chainguard-jdk26valhalla-musl`
    *   `ci-distroless-jre25`
    *   `ci-distroless-jre25-musl`
    *   `ci-distroless-jre26ea`
    *   `ci-distroless-jre26ea-musl`
    *   `ci-distroless-jre26valhalla`
    *   `ci-distroless-jre26valhalla-musl`
    *   `ci-ubi9-jdk25`
    *   `ci-ubi9-jdk26ea`
    *   `ci-ubi9-jdk26valhalla`

### Logic Flow

No logic changes are required within the steps. The existing steps for `docker buildx bake`, `syft`, `trivy`, `grype`, and `cosign` are generic and operate on `${{ matrix.target }}`. They will automatically handle the new targets correctly:
*   **Build:** Will respect the `platforms=["linux/amd64"]` definition for `ci-*` targets in `docker-bake.hcl`.
*   **Sign/Attest:** Will correctly sign the single-arch manifests.

## Verification

*   **Trigger:** Push to `main`.
*   **Observation:** 30 jobs should spawn (15 prod + 15 CI).
*   **Result:** `ci-` tags appear in GHCR with signatures.
