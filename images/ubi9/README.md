# UBI 9 Minimal Images

- Based on Red Hat UBI 9 minimal
- Include Temurin JDK 25, JDK 26 EA, or Valhalla EA under `/usr/lib/jvm/`
- Non-root user `runner` (65532)
- Suitable for UBI-certified environments; consider FIPS variants as future work

Temurin binaries are GPLv2 with Classpath Exception; review `/usr/lib/jvm/jdk-*/legal` for notices.
