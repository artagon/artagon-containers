# Distroless Runtimes

Distroless targets provide jlink-minimized Java runtimes.

- `distroless-jre25`: glibc base, includes modules `java.base, java.logging, jdk.crypto.ec, jdk.crypto.cryptoki, jdk.management, jdk.unsupported`
- `distroless-jre25-musl`: built on `distroless/static` for static musl workloads
- Provide own classpath; image contains no package manager, shell, or root user
- Suggested runtime flags: `--read-only --tmpfs /tmp`

Temurin binaries are GPLv2 with Classpath Exception; see `/usr/lib/jvm/jre-*/legal` inside the image for notices.
