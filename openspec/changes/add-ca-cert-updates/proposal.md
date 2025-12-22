# Proposal: Automated CA Certificate & CRL Updates

## Context
Container images must ship with the latest Certificate Authority (CA) certificates and revocation lists to ensure secure TLS connections and trust. Stale certificates can lead to security vulnerabilities (trusting compromised CAs) or availability issues (rejecting valid new CAs).

## Goal
Ensure all `artagon-containers` images (Chainguard, UBI9, Distroless) invariably contain the most recent `ca-certificates` bundle available at build time.

## Strategy by Image Type

### 1. Chainguard (Wolfi)
**Current State:** Base image `cgr.dev/chainguard/wolfi-base` is pinned by digest.
**Problem:** The base image might be days/weeks old.
**Proposed Change:**
Explicitly install/upgrade `ca-certificates` in the **runtime** stage of the Dockerfile.
```dockerfile
# Dockerfile (Runtime Stage)
RUN apk add --no-cache ca-certificates
```
This forces the package manager to fetch the latest bundle from the Wolfi repositories during every build, regardless of the base image's age.

### 2. Red Hat UBI 9
**Current State:** Base image `registry.access.redhat.com/ubi9-minimal` is pinned by digest.
**Proposed Change:**
Explicitly update `ca-certificates` in the **runtime** stage.
```dockerfile
# Dockerfile (Runtime Stage)
RUN microdnf update -y ca-certificates && microdnf clean all
```
This ensures the final image layer applies any pending updates to the cert bundle.

### 3. Google Distroless
**Current State:** Inherits from `gcr.io/distroless/base-debian12`.
**Constraint:** Distroless images do not contain a package manager (`apt`/`dpkg`) or shell. We cannot run "install" commands.
**Proposed Change:**
Rely on **Dependabot/Renovate** to update the base image digest daily.
- Distroless rebuilds their images frequently with Debian updates.
- Our `daily` Dependabot schedule for Docker ensures we pull the absolute latest base image digest.
- **Alternative (High Effort):** Copy `ca-certificates.crt` from a Debian builder stage, but this risks drift from the base OS. Relying on the base image is the standard pattern for Distroless.

## Automation & Verification

### 1. Build-Time Fetching
The `docker build` process (running in GitHub Actions) will pull the latest packages.
- **Cache Busting:** We must ensure Docker layer caching doesn't mask updates.
- **Solution:** The `docker-bake.hcl` already injects `SOURCE_DATE_EPOCH`. We can strictly disable caching for the specific "update certs" layer or rely on the `daily` build cadence where we effectively rebuild the world.

### 2. Verification Test
Add a step to the `health-check.sh` or a separate CI test to verify the timestamp or version of the CA bundle.
- **Command:** `ls -l /etc/ssl/certs/ca-certificates.crt` (or distro equivalent).

## Implementation Plan
1.  **Refactor Dockerfiles:** Add the install/update commands to Chainguard and UBI9 Dockerfiles.
2.  **Verify Distroless:** Confirm Dependabot is tracking the `gcr.io/distroless` digests correctly.
3.  **Documentation:** Update `SECURITY.md` to mention this "freshness" guarantee.

## Runtime Revocation Checking (CRLs & OCSP)

While the build-time updates described above ensure the *Root Certificate Authority* store is current, verifying the status of individual intermediate or leaf certificates (revocation) happens at **runtime**.

Users of these images should configure their Java applications to perform active revocation checking. The JDK supports standard protocols like CRL (Certificate Revocation Lists) and OCSP (Online Certificate Status Protocol).

### 1. CRL Checking (Certificate Revocation Lists)
To enable legacy CRL checking, where the JDK downloads the full list of revoked certificates from the Distribution Point (CRLDP) specified in the certificate:
*   **System Property:** `-Dcom.sun.net.ssl.checkRevocation=true`
*   **System Property:** `-Dcom.sun.security.enableCRLDP=true`

### 2. OCSP Checking (Online Certificate Status Protocol)
To enable real-time validation checks with the CA's OCSP responder:
*   **Security Property:** `ocsp.enable=true` (Set in `java.security` file or via `Security.setProperty()`)
*   **System Property:** `-Dcom.sun.security.enableAIAcaIssuers=true` (Ensures issuer certificates can be fetched via Authority Information Access extension if missing).

### 3. OCSP Stapling (TLS Status Request)
To reduce the latency of OCSP lookups, enable "Stapling", where the server presents its own valid signed OCSP response during the TLS handshake:
*   **System Property:** `-Djdk.tls.client.enableStatusRequestExtension=true` (Available in Java 8u261+ and later).

