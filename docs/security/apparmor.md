# AppArmor Profile Usage

## Overview

The `security/apparmor-java.txt` profile restricts filesystem access for JVM workloads while keeping read access to the JDK and application workspace and write access to `/tmp`.

## Load the Profile (Linux Hosts)

```bash
sudo apparmor_parser -r security/apparmor-java.txt
```

Verify it is loaded:

```bash
sudo apparmor_status | grep artagon-java
```

## Docker

```bash
docker run --rm \
  --security-opt apparmor=artagon-java \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25 \
  java -version
```

## Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: java-app
  annotations:
    container.apparmor.security.beta.kubernetes.io/app: localhost/artagon-java
spec:
  containers:
  - name: app
    image: ghcr.io/artagon/artagon-containers:distroless-jre25
```

**Note**: The profile must be installed on each node at `/etc/apparmor.d/` or loaded via `apparmor_parser`.

## Troubleshooting

### Profile not found

- Ensure `apparmor_parser` is installed and the profile is loaded.
- Check with `sudo apparmor_status`.

### Permission denied errors

- Review kernel audit logs:

```bash
sudo journalctl -k | grep apparmor
```

- If a legitimate path is blocked, extend the profile by adding an allow rule.

## Reference

- [AppArmor Documentation](https://wiki.ubuntu.com/AppArmor)
