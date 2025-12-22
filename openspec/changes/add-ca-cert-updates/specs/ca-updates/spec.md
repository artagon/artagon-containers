# CA Certificate & CRL Updates Spec

## Problem

Container images often lag behind on Certificate Authority (CA) updates because they rely on the static contents of their base image. If a CA is revoked or a new one is added, the container might trust a compromised entity or fail to connect to a valid service until the base image is updated and the application is rebuilt.

## Solution

The build system will explicitly force an update of the `ca-certificates` package (and any associated CRL packages if available) during the **runtime stage** of the Docker build. This ensures that every newly built image contains the latest trust store available from the OS vendor at the moment of the build, regardless of the age of the pinned base image.

## Implementation Details

### 1. Chainguard (Wolfi)

*   **File:** `images/chainguard/Dockerfile.*`
*   **Action:** In the final `runtime` stage (both `runtime-glibc` and `runtime-musl`), insert:
    ```dockerfile
    RUN apk add --no-cache ca-certificates
    ```
    This command upgrades the package if a newer version exists in the repo compared to what's in the base image.

### 2. Red Hat UBI 9

*   **File:** `images/ubi9/Dockerfile.*`
*   **Action:** In the final stage, insert:
    ```dockerfile
    RUN microdnf update -y ca-certificates && microdnf clean all
    ```

### 3. Distroless

*   **File:** `images/distroless/Dockerfile.*`
*   **Action:** No Dockerfile changes possible (no shell/package manager).
*   **Strategy:** Maintain strict daily Dependabot updates for the base image digests. Add a comment in the Dockerfile explicitly stating this dependency:
    ```dockerfile
    # Note: ca-certificates are updated solely via base image digest updates.
    ```

## Verification

*   **Build Logs:** Verify that the package manager output shows `ca-certificates` being checked/upgraded.
*   **Runtime:** Inspecting the image should show the timestamp of `/etc/ssl/certs/ca-certificates.crt` (or equivalent) being recent.

## Runtime Configuration Guide: Revocation Checking

This specification primarily addresses the *static trust anchor* (Root CAs). However, a complete security posture requires checking for *revoked* certificates at runtime. The following configurations are recommended for applications running in these containers.

### 1. Enabling CRL (Certificate Revocation Lists)

CRLs are large lists of revoked serial numbers downloaded from the CA.
*   **Method:** Set Java System Properties.
*   **Key Properties:**
    *   `com.sun.net.ssl.checkRevocation=true`: Master switch for revocation checking.
    *   `com.sun.security.enableCRLDP=true`: Enables fetching CRLs from the "CRL Distribution Points" extension in the certificate.

### 2. Enabling OCSP (Online Certificate Status Protocol)

OCSP performs a lightweight, real-time status check for a specific certificate.
*   **Method:** Set Java Security Property (preferred) or System Property.
*   **Key Properties:**
    *   `ocsp.enable=true`: **Security Property** (set in `java.security`). This is the standard way to enable OCSP.
    *   `com.sun.security.enableAIAcaIssuers=true`: **System Property**. Vital for incomplete chains; allows fetching the issuer certificate via the "Authority Information Access" extension.

### 3. Enabling OCSP Stapling

Stapling improves performance and privacy by having the server provide the OCSP response.
*   **Method:** Set Java System Property.
*   **Key Property:**
    *   `jdk.tls.client.enableStatusRequestExtension=true`: Enables the client to request the OCSP response in the TLS handshake.

