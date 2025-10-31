# Chainguard Images

- Base: `cgr.dev/chainguard/wolfi-base` (musl, minimal)
- Variants: JDK 25 GA, JDK 26 EA, JDK 26 Valhalla
- Path: `/usr/lib/jvm/jdk-<flavor>`
- User: `runner` (uid/gid 65532)
- Recommended flags: `--read-only --tmpfs /tmp --cap-drop=ALL --security-opt=no-new-privileges:true`

Oracle/Temurin binaries are GPLv2 with Classpath Exception. See upstream `LICENSE` inside `/usr/lib/jvm/jdk-*/legal`.
