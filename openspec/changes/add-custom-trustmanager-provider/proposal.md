# Proposal: Custom TrustManager Provider via Security Provider

## Context
Standard JDK trust management relies on file-based keystores (`cacerts`). In dynamic container environments, or for complex trust scenarios (e.g., dynamic CA reloading, hybrid trust models), a static file is insufficient. Users may wish to "install" a custom trust logic globally for the JVM without modifying application code.

## Goal
Enable the installation of a custom `TrustManager` at the JDK level using the Java Security Provider mechanism (Option 4). This allows a custom implementation to be registered via `java.security` configuration, making it transparent to applications.

## Strategy

1.  **Develop a Custom Security Provider:**
    *   Create a Java library (JAR) implementing `java.security.Provider`.
    *   Register a `TrustManagerFactory` service within this provider.
    *   Implement the `TrustManagerFactorySpi` and `X509TrustManager` to define the custom trust logic.

2.  **Deployment in Container:**
    *   Place the JAR in the classpath (e.g., `JAVA_HOME/lib/ext` or app classpath).
    *   Update `JAVA_HOME/conf/security/java.security` to register the provider (e.g., `security.provider.15=com.artagon.security.CustomTrustProvider`).
    *   Optionally set the default TrustManagerFactory algorithm to the custom one: `ssl.TrustManagerFactory.algorithm=CustomAlgo`.

## Benefits
*   **Transparency:** Applications using standard `SSLContext.getDefault()` or `TrustManagerFactory.getInstance(getDefaultAlgorithm())` automatically use the custom logic.
*   **No Code Changes:** Applications do not need to be recompiled or modified.
*   **Centralized Control:** Trust policy is defined in one place (the provider) for the entire container.

## Risks
*   **Complexity:** Implementing a correct and secure `X509TrustManager` is non-trivial.
*   **Compatibility:** Some applications hardcode `PKIX` or `SunX509` algorithms, bypassing the default configuration.
