# Tasks: Custom TrustManager Provider

- [ ] Create a proof-of-concept Java project for `ArtagonSecurityProvider`.
- [ ] Implement `ArtagonTrustManagerFactory` and a sample `X509TrustManager`.
- [ ] Build the JAR file.
- [ ] Create a test Dockerfile extending one of the `artagon-containers` images.
- [ ] COPY the JAR to the JDK extension directory or classpath.
- [ ] Modify `java.security` in the Dockerfile to register the provider.
- [ ] Verify that a sample Java application picks up the custom TrustManager.
