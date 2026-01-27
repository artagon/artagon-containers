# Fix Workflow YAML Issues and Add Testing Strategy

## Why

The CI workflows have recurring YAML syntax and permission issues that are only caught after pushing to GitHub. Current issues include:
1. SLSA generator workflow permission mismatch (`actions: read` vs `actions: none`)
2. Python heredocs breaking YAML parsing (already fixed by extracting to scripts)
3. No local validation before push

This results in multiple failed CI runs and wasted time debugging workflow issues after merge.

## What Changes

1. **Fix SLSA Permissions**: Update `build-push.yml` and `release.yml` to grant proper permissions for the SLSA provenance generator workflow.

2. **Add Workflow Testing with `act`**: Implement local workflow testing using [nektos/act](https://github.com/nektos/act) to catch issues before push.

3. **Add Devcontainer Support**: Configure devcontainer with `act` and workflow validation tools pre-installed.

4. **Add Pre-commit Validation**: Add workflow YAML linting to catch syntax errors before commit.

## Impact

**Affected specs**:
- `workflow-testing` (NEW) - Local workflow validation and testing

**Affected code**:
- `.github/workflows/build-push.yml` - Fix SLSA permissions
- `.github/workflows/release.yml` - Fix SLSA permissions
- `.devcontainer/devcontainer.json` (NEW) - Devcontainer configuration
- `.actrc` (NEW) - Act configuration
- `Makefile` - Add workflow test targets

**Benefits**:
- Catch workflow errors before push
- Faster iteration on CI changes
- Reduced failed CI runs
- Better developer experience with devcontainer

**Risks**:
- `act` doesn't perfectly replicate GitHub Actions environment
- Some actions may not work locally (e.g., OIDC, secrets)
