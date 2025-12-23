# Spec: Custom TrustManager Provider

## Component Definition

### 1. CustomProvider Class
Must extend `java.security.Provider`.
```java
public class ArtagonSecurityProvider extends Provider {
    public ArtagonSecurityProvider() {
        super("ArtagonSec", 1.0, "Artagon Custom Security Provider");
        put("TrustManagerFactory.ArtagonTrust", "com.artagon.security.ArtagonTrustManagerFactory");
    }
}
```

### 2. TrustManagerFactorySpi Implementation
Must extend `javax.net.ssl.TrustManagerFactorySpi`.
*   **`engineInit(KeyStore ks)`:** Loads the trust material (can ignore the passed KeyStore if using a dynamic source).
*   **`engineGetTrustManagers()`:** Returns an array containing the custom `X509TrustManager`.

### 3. X509TrustManager Implementation
Must extend `javax.net.ssl.X509TrustManager` (and optionally `X509ExtendedTrustManager` for connection-sensitive checks).
*   **`checkServerTrusted` / `checkClientTrusted`:** Implementation of the validation logic (e.g., call standard PKIX validator + custom checks, or merge multiple trust stores).

## Configuration

### File: `java.security`
Located at `$JAVA_HOME/conf/security/java.security`.

1.  **Register Provider:**
    Find the list of providers (`security.provider.N`) and add the custom one. Order matters; if replacing the default, it might need a lower number (higher priority) or explicit selection.
    ```properties
    security.provider.14=com.artagon.security.ArtagonSecurityProvider
    ```

2.  **Set Default Algorithm (Optional but Recommended):**
    To force all standard factories to use this provider by default:
    ```properties
    ssl.TrustManagerFactory.algorithm=ArtagonTrust
    ```

## Verification

To verify the installation:
1.  Run a simple Java program that prints `TrustManagerFactory.getDefaultAlgorithm()`.
2.  Inspect the TrustManagers returned by `TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm()).getTrustManagers()`.
3.  Check if the class name matches the custom implementation.
