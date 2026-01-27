# Workflow Testing Specification

## Overview

Local workflow validation and testing infrastructure to catch GitHub Actions issues before push.

## Requirements

### Workflow Validation

1. **Syntax Validation**: All workflow YAML files must pass `actionlint` before merge
2. **Permission Validation**: Reusable workflow calls must have compatible permissions
3. **Local Testing**: Developers can run workflow jobs locally using `act`

### Tooling

| Tool | Purpose | Required |
|------|---------|----------|
| `actionlint` | YAML syntax and semantic validation | Yes |
| `act` | Local workflow execution | Optional |
| `gh` | GitHub CLI for workflow inspection | Yes |

### Development Environment (Nix)

The `flake.nix` provides a reproducible development shell with:
- Container tools: `docker`, `docker-buildx` (CLI only - daemon must run on host)
- GitHub Actions testing: `act`, `actionlint`
- Security tools: `cosign`, `syft`, `grype`, `trivy`
- Build tools: `gnumake`, `jq`, `yq-go`, `python3`, `gh`

Usage:
```bash
nix develop           # Enter development shell
# or with direnv:
echo "use flake" > .envrc && direnv allow
```

## Validation Rules

### Permission Compatibility

When calling reusable workflows, the caller must grant **at least** the permissions the callee requests:

```yaml
# Caller (build-push.yml)
provenance:
  permissions:
    actions: read      # Required by slsa-github-generator
    id-token: write    # Required for OIDC
    contents: read
    packages: write
```

### YAML Heredocs

Python/shell heredocs in workflow `run` blocks must either:
1. Be extracted to script files (preferred)
2. Use proper YAML multiline syntax without column-0 content

## Testing Strategy

### Pre-commit

```bash
make lint-workflows  # Runs actionlint on all workflow files
```

### Local CI Simulation

```bash
make test-ci         # Runs ci-build.yml locally with act
```

### Limitations

`act` cannot replicate:
- GitHub OIDC tokens
- Repository secrets (must use `.secrets` file)
- Some GitHub-hosted runner features
- Reusable workflow calls to external repos
