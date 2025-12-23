# Seccomp Profile Usage

## Overview

The `security/seccomp-java.json` profile restricts container syscalls to only those necessary for JVM operation, reducing the kernel attack surface by blocking dangerous syscalls like `ptrace`, `process_vm_readv`, and `bpf`.

## Quick Start

### Docker

```bash
docker run --rm \
  --security-opt seccomp=security/seccomp-java.json \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25 \
  java -jar /workspace/app.jar
```

### Docker Compose

```yaml
version: '3.8'
services:
  app:
    image: ghcr.io/artagon/artagon-containers:ubi9-jdk25
    security_opt:
      - seccomp:security/seccomp-java.json
```

### Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: java-app
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: localhost/seccomp-java.json
spec:
  containers:
  - name: app
    image: ghcr.io/artagon/artagon-containers:distroless-jre25
```

**Note**: Copy `security/seccomp-java.json` to `/var/lib/kubelet/seccomp/` on each node.

## What's Blocked

The profile blocks dangerous syscalls including:
- `ptrace` - Process tracing (container escape vector)
- `process_vm_readv`, `process_vm_writev` - Cross-process memory access
- `bpf` - Berkeley Packet Filter (privilege escalation)
- `perf_event_open` - Performance monitoring (information disclosure)
- `personality` - Execution domain changes
- `pivot_root`, `mount`, `umount` - Filesystem manipulation
- `reboot`, `swapon`, `swapoff` - System control

## What's Allowed

Essential JVM syscalls:
- File I/O: `read`, `write`, `open`, `close`, `lseek`, `stat`
- Memory: `mmap`, `munmap`, `mprotect`, `brk`
- Threading: `clone`, `futex`, `set_tid_address`
- Signals: `rt_sigaction`, `rt_sigprocmask`, `rt_sigreturn`
- Time: `clock_gettime`, `nanosleep`
- Network: `socket`, `bind`, `connect`, `accept`, `send`, `recv`

## Troubleshooting

### Symptom: Application fails with "Operation not permitted"

**Diagnose**:
```bash
# Check kernel audit log for blocked syscalls
dmesg | grep audit | grep SECCOMP

# Or use auditd
ausearch -m SECCOMP -ts recent
```

**Solution**:
1. Identify the blocked syscall from audit logs
2. Verify it's necessary for your application
3. Add to the profile's `syscalls` array:

```json
{
  "names": ["your_syscall_here"],
  "action": "SCMP_ACT_ALLOW"
}
```

### Common Issues

**Native libraries require additional syscalls**:
- JNI libraries may need `execve`, `vfork`
- Add them explicitly to your custom profile

**Container crashes on startup**:
- Verify profile syntax: `cat security/seccomp-java.json | jq`
- Test without profile first to isolate issue

## Extending the Profile

Create a custom profile for your application:

```bash
# Copy baseline profile
cp security/seccomp-java.json security/seccomp-myapp.json

# Edit to add application-specific syscalls
# Example: Add execve for process spawning
jq '.syscalls[0].names += ["execve"]' security/seccomp-myapp.json > tmp && mv tmp security/seccomp-myapp.json

# Use custom profile
docker run --security-opt seccomp=security/seccomp-myapp.json <image>
```

## Validation

### Test with seccomp enabled

```bash
# Run smoke tests
docker run --security-opt seccomp=security/seccomp-java.json \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25 \
  java -version

# Run full application
docker run --security-opt seccomp=security/seccomp-java.json \
  -v "$(pwd)/app:/workspace:ro" \
  ghcr.io/artagon/artagon-containers:ubi9-jdk25 \
  java -jar /workspace/app.jar
```

### Verify syscall filtering

```bash
# Check seccomp status inside container
docker run --security-opt seccomp=security/seccomp-java.json \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25 \
  grep Seccomp /proc/self/status

# Expected output:
# Seccomp: 2 (filtering enabled)
```

## Architecture Support

The profile supports both `linux/amd64` and `linux/arm64` via architecture mappings:
- `SCMP_ARCH_X86_64` (includes `SCMP_ARCH_X86`, `SCMP_ARCH_X32`)
- `SCMP_ARCH_AARCH64` (includes `SCMP_ARCH_ARM`)

## Framework Compatibility

Tested with:
- ✅ Spring Boot (all versions)
- ✅ Quarkus (native and JVM mode)
- ✅ Micronaut
- ✅ Vert.x
- ✅ Plain Java applications

## Performance Impact

Seccomp filtering adds <1% CPU overhead for typical Java applications. The security benefit far outweighs the minimal performance cost.

## References

- [Seccomp BPF Documentation](https://www.kernel.org/doc/Documentation/prctl/seccomp_filter.txt)
- [Docker Seccomp Guide](https://docs.docker.com/engine/security/seccomp/)
- [CIS Docker Benchmark 5.21](https://www.cisecurity.org/benchmark/docker/)
