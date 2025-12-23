# Secure Deployment Patterns

This guide shows recommended runtime settings for hardened JVM containers.

## Docker

```bash
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,exec,nosuid,nodev \
  --cap-drop=ALL \
  --security-opt no-new-privileges:true \
  --security-opt seccomp=security/seccomp-java.json \
  --security-opt apparmor=artagon-java \
  -v "$(pwd)/app:/workspace:ro" \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25 \
  java -jar /workspace/app.jar
```

## Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-java-app
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: localhost/seccomp-java.json
    container.apparmor.security.beta.kubernetes.io/app: localhost/artagon-java
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 65532
    runAsGroup: 65532
    fsGroup: 65532
  containers:
  - name: app
    image: ghcr.io/artagon/artagon-containers:distroless-jre25
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: [ALL]
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: app
      mountPath: /workspace
      readOnly: true
  volumes:
  - name: tmp
    emptyDir: {}
  - name: app
    configMap:
      name: java-app
```

## Docker Compose

```yaml
version: "3.8"
services:
  app:
    image: ghcr.io/artagon/artagon-containers:ubi9-jdk25
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
      - seccomp:security/seccomp-java.json
      - apparmor:artagon-java
    volumes:
      - ./app:/workspace:ro
```

**Note**: Requires Docker Compose v2+ for `security_opt` and `tmpfs` support.

## Read-Only RootFS Notes

- Java writes temporary files to `/tmp`. Always mount tmpfs when using read-only rootfs.
- If your application writes elsewhere (for example `/workspace`), mount a writable volume for that path.

## Image Hardening Checklist

- Read-only rootfs with tmpfs for `/tmp`.
- Drop all Linux capabilities.
- Enable `no-new-privileges`.
- Apply seccomp and AppArmor profiles.
- Run as non-root UID/GID 65532.

## Production Checklist

- [ ] Verify image signature with Cosign
- [ ] Review SBOM for known vulnerabilities
- [ ] Enable read-only root filesystem with tmpfs mounts
- [ ] Drop all Linux capabilities
- [ ] Apply seccomp profile
- [ ] Apply AppArmor profile (if available)
- [ ] Configure health checks
- [ ] Set resource limits (CPU, memory)
- [ ] Configure logging and monitoring
- [ ] Test disaster recovery procedures

## Runtime Validation

```bash
# Verify non-root user
docker exec <container> id

# Verify read-only rootfs
docker exec <container> sh -c 'touch /root/test || echo "read-only rootfs"'

# Verify seccomp is enabled (if grep available)
docker exec <container> grep Seccomp /proc/self/status
```

For Distroless images (no shell/coreutils), use `docker inspect` to verify `Config.User` and `Config.Healthcheck`.
