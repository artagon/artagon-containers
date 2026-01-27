# Proposal: Replace Custom Digest Refresh with Renovate

## Why

PR #45 introduced a custom solution for base image digest management with lock files and shell scripts. While functional, this approach:

- Requires ongoing maintenance of custom scripts
- Lacks retry logic, rate limiting, and error handling at scale
- Only supports Docker (not Helm, npm, or other ecosystems)
- Doesn't handle PR conflict resolution automatically

Renovate is an industry-standard dependency management tool that handles all of this out of the box.

## What

Replace the custom digest-refresh workflow with Renovate:

1. **Add Renovate configuration** (`renovate.json`)
   - Enable `docker:pinDigests` preset
   - Configure weekly schedule (Monday 06:00 UTC)
   - Group base image updates together

2. **Update Dockerfiles** to use Renovate's digest pinning format:
   ```dockerfile
   # Before (tag only)
   FROM cgr.dev/chainguard/wolfi-base:latest

   # After (tag + digest, Renovate-managed)
   FROM cgr.dev/chainguard/wolfi-base:latest@sha256:abc123...
   ```

3. **Enable Renovate** via GitHub App or self-hosted action

4. **Deprecate custom scripts** (keep for reference or remove entirely)

## Impact

### Removed/Deprecated
- `.github/workflows/digest-refresh.yml` - replaced by Renovate
- `scripts/refresh-versions.sh` - no longer needed
- `scripts/lockfile-util.sh` - no longer needed
- `versions/*.lock` - Renovate manages digests inline in Dockerfiles

### Added
- `renovate.json` - Renovate configuration
- Inline digest pins in all Dockerfiles

### Modified
- All Dockerfiles updated to include `@sha256:...` digest pins
- `docker-bake.hcl` - remove digest variables (optional, can keep for manual override)

## Benefits

| Aspect | Custom Solution | Renovate |
|--------|-----------------|----------|
| Maintenance | Team-maintained | Community-maintained |
| Error handling | Basic | Robust (retries, rate limits) |
| Ecosystems | Docker only | Docker, npm, Helm, K8s, Terraform, etc. |
| PR management | Manual | Auto-rebase, conflict resolution |
| Scheduling | Basic cron | Rich schedule expressions |
| Grouping | None | Group related updates |
| Dashboard | None | Dependency dashboard issue |

## Links

- Issue: #46
- Supersedes: #44, PR #45
- [Renovate Docker Docs](https://docs.renovatebot.com/docker/)
