# Contributing to Artagon Containers

This guide covers the development workflow, conventions, and best practices for contributing to the Artagon Containers project.

## Development Workflow

The project follows an **issue-driven workflow**: "Issue → Branch → Commits → PR → Review → Merge"

### Prerequisites

Before you begin contributing, ensure you have the following tools installed:

**Required**:
- **Git**: 2.30 or later
- **Docker**: 24.0 or later with BuildKit support
- **Docker Buildx**: Multi-platform build plugin
- **Bash**: 4.0 or later (for build scripts)
- **Python 3**: For JDK resolution scripts
- **jq**: JSON parsing in build scripts and workflows
- **curl**: For downloading JDK binaries and metadata

**Security Tools** (required for full validation):
- **Cosign**: Image signing and verification (`brew install cosign` or install script)
- **Syft**: SBOM generation (`brew install syft` or install script)
- **Trivy**: Vulnerability scanning (`brew install trivy` or install script)
- **Grype**: Additional vulnerability scanning (`brew install grype` or install script)
- **Hadolint**: Dockerfile linting (`brew install hadolint` or download binary)
- **Dockle**: Container image security linter (`brew install dockle` or install script)

**Optional**:
- **GitHub CLI (gh)**: For PR and issue management
- **Nix**: For reproducible development environments
- **make**: Build automation (usually pre-installed on Unix systems)

### Installation Scripts

```bash
# Install security tooling on Linux
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

# Install Cosign
brew install cosign
# OR
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)"
chmod +x cosign-*
sudo mv cosign-* /usr/local/bin/cosign

# Install Hadolint
brew install hadolint
# OR
wget https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -O hadolint
chmod +x hadolint
sudo mv hadolint /usr/local/bin/

# Install Dockle
brew install dockle
# OR
curl -sSfL https://raw.githubusercontent.com/goodwithtech/dockle/master/install.sh | sudo sh -s -- -b /usr/local/bin
```

### Initial Setup

1. **Fork the repository** on GitHub to your personal account

2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/artagon-containers.git
   cd artagon-containers
   ```

3. **Add upstream remote** to track the main repository:
   ```bash
   git remote add upstream https://github.com/artagon/artagon-containers.git
   git fetch upstream
   ```

4. **Verify your environment**:
   ```bash
   # Check Docker version
   docker version
   docker buildx version

   # Check required tools
   which python3 jq curl bash

   # Verify security tools
   cosign version
   syft version
   trivy --version
   grype version
   hadolint --version
   dockle --version
   ```

5. **Test a local build**:
   ```bash
   # Build a single-platform image for testing
   make build TYPE=chainguard FLAVOR=jdk25

   # Run the built image
   docker run --rm ghcr.io/artagon/artagon-containers:chainguard-jdk25 java --version
   ```

## Semantic Commits

All commit messages must follow a structured format with type, scope, and subject. This enables automated changelog generation and semantic versioning.

### Commit Message Format

```
<type>(<scope>): <subject>

[optional body with detailed explanation]

[optional footer with issue references]
```

**Rules**:
- Subject line: 50 characters or less
- Body: Wrap at 72 characters
- Use imperative mood ("add feature" not "added feature")
- Capitalize first letter of subject
- No period at end of subject line
- Separate subject from body with blank line
- Include "Closes #N" in footer to auto-close issues

### Commit Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New functionality or image variant | `feat(distroless): add jre26valhalla musl variant` |
| `fix` | Bug corrections or security patches | `fix(scripts): use Alpine builder for distroless musl variants` |
| `docs` | Documentation updates only | `docs(readme): add verification examples` |
| `style` | Code formatting (no functional changes) | `style(dockerfiles): standardize whitespace` |
| `refactor` | Code restructuring without behavior changes | `refactor(resolve): extract arch mapping to function` |
| `perf` | Performance improvements | `perf(build): enable inline cache for buildx` |
| `test` | Adding or correcting tests | `test(sbom): validate CycloneDX format` |
| `build` | Build system, Dockerfile, or Makefile changes | `build(makefile): add digest signing support` |
| `ci` | CI/CD workflow modifications | `ci(workflows): add retry logic for apk installs` |
| `chore` | Maintenance tasks, dependency updates | `chore(deps): update Chainguard base digest` |

### Scopes (Optional but Recommended)

**Base Types**:
- `chainguard`: Changes specific to Chainguard images
- `distroless`: Changes specific to Distroless images
- `ubi9`: Changes specific to UBI9 images

**JDK Versions**:
- `jdk25`: JDK 25 GA specific changes
- `jdk26ea`: JDK 26 EA specific changes
- `jdk26valhalla`: JDK 26 Valhalla specific changes

**Infrastructure**:
- `scripts`: Build or resolution script changes
- `workflows`: GitHub Actions workflow changes
- `makefile`: Makefile changes
- `bake`: Docker Bake configuration changes

**Security**:
- `sbom`: SBOM generation or attestation
- `signing`: Image signing or verification
- `scanning`: Vulnerability scanning configuration

### Commit Examples

```bash
# Adding a new feature
git commit -m "feat(chainguard): add jdk26 early access variant

Includes Dockerfile and Bake target for JDK 26 EA builds
using Artagon homebrew tap as source.

Closes #42"

# Fixing a bug
git commit -m "fix(scripts): handle missing musl builds gracefully

Fall back to glibc variant with Alpine builder when musl
binaries are not available from upstream sources.

Closes #38"

# Documentation update
git commit -m "docs(security): add hardening guidance for read-only rootfs"

# Build system change
git commit -m "build(makefile): ensure digest lookup handles multi-arch manifests"

# CI/CD workflow update
git commit -m "ci(build-push): add retry logic for distroless builder apk installs

Mitigates transient network failures during package installation
in multi-stage builds.

Closes #45"

# Dependency update
git commit -m "chore(deps): update Chainguard wolfi-base to latest digest"

# Multiple changes in one commit (avoid if possible)
git commit -m "feat(distroless): add musl support for all JDK variants

- Update Dockerfiles to support static base image
- Modify resolve script to handle musl fallback logic
- Add Bake targets for musl variants

Closes #50"
```

### Commit Best Practices

- **Make atomic commits**: Each commit should represent one logical change
- **Commit frequently**: Don't wait to bundle multiple unrelated changes
- **Test before committing**: Ensure builds succeed and scans pass
- **Reference issues**: Always include "Closes #N" for issue-driven work
- **Write descriptive bodies**: Explain "why" not just "what" for complex changes

## Branch Naming Convention

Feature and fix branches must follow a consistent naming pattern that includes the issue number and type prefix.

### Branch Format

```
<type>/<issue-number>-<short-description>
```

**Rules**:
- Use lowercase only
- Replace spaces with hyphens
- Always include the issue number
- Keep descriptions concise (3-5 words maximum)
- Match the primary commit type for the branch

### Branch Type Prefixes

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feat/` | New features or capabilities | `feat/42-add-jdk26-valhalla` |
| `fix/` | Bug fixes | `fix/38-musl-fallback-logic` |
| `docs/` | Documentation changes | `docs/50-add-contributing-guide` |
| `build/` | Build system updates | `build/55-digest-signing` |
| `ci/` | CI/CD workflow changes | `ci/45-apk-retry-logic` |
| `refactor/` | Code restructuring | `refactor/60-simplify-resolver` |
| `chore/` | Maintenance tasks | `chore/65-update-base-digests` |

### Branch Examples

```bash
# Creating a feature branch
git checkout -b feat/42-add-cpp26-bazel-support

# Creating a fix branch
git checkout -b fix/38-handle-musl-fallback

# Creating a documentation branch
git checkout -b docs/50-update-security-policy

# Creating a CI branch
git checkout -b ci/45-add-build-retry-logic

# Creating a chore branch
git checkout -b chore/65-bump-chainguard-digest
```

### Automated Branch Name Generation

You can create a script to generate compliant branch names from issue titles:

```bash
#!/usr/bin/env bash
# scripts/create-branch.sh
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <type> <issue-number> [description]"
  echo "Example: $0 feat 42 'add jdk26 valhalla support'"
  exit 1
fi

TYPE="$1"
ISSUE="$2"
DESC="${3:-}"

if [ -z "$DESC" ]; then
  # Fetch issue title from GitHub API if gh CLI is available
  if command -v gh &> /dev/null; then
    DESC=$(gh issue view "$ISSUE" --json title -q .title)
  else
    echo "Error: Description required when gh CLI not available"
    exit 1
  fi
fi

# Convert to lowercase and replace spaces/special chars with hyphens
SLUG=$(echo "$DESC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Limit to first 5 words
SLUG=$(echo "$SLUG" | cut -d'-' -f1-5)

BRANCH="${TYPE}/${ISSUE}-${SLUG}"
echo "Creating branch: $BRANCH"
git checkout -b "$BRANCH"
```

Usage:
```bash
chmod +x scripts/create-branch.sh
./scripts/create-branch.sh feat 42 "add jdk26 valhalla support"
# Creates: feat/42-add-jdk26-valhalla-support
```

## Pull Request Requirements

Pull requests are the primary mechanism for contributing changes. All PRs must meet quality gates before merging.

### PR Workflow

1. **Create an issue first** (if one doesn't exist) describing the problem or feature
2. **Create a branch** following the naming convention
3. **Make changes** with semantic commits
4. **Test locally** using make targets
5. **Push to your fork**:
   ```bash
   git push origin feat/42-add-jdk26-valhalla
   ```
6. **Open a PR** from your fork to `artagon/artagon-containers:main`
7. **Fill out the PR template** completely
8. **Respond to review feedback** by pushing additional commits
9. **Wait for approval** and CI checks to pass
10. **Maintainer merges** using squash or merge commit

### PR Title Format

PR titles must follow the same semantic commit format as commit messages:

```
<type>(<scope>): <subject>
```

**Examples**:
- `feat(chainguard): add jdk26valhalla musl variant`
- `fix(scripts): handle missing musl builds gracefully`
- `ci(workflows): add retry logic for apk installs`
- `docs(readme): add cosign verification examples`

### PR Description Template

```markdown
## Summary
Brief description of what this PR accomplishes.

## Changes
- Bullet point list of specific changes made
- Include new files, modified files, and deleted files
- Highlight any breaking changes or deprecations

## Related Issues
Closes #42

## Testing Performed
- [ ] Local build succeeded: `make build TYPE=chainguard FLAVOR=jdk25`
- [ ] SBOM generation succeeded: `make sbom TYPE=chainguard FLAVOR=jdk25`
- [ ] Vulnerability scans passed: `make scan TYPE=chainguard FLAVOR=jdk25`
- [ ] Dockerfile linting passed: `make lint`
- [ ] Image runs successfully with test workload
- [ ] Multi-arch manifest builds correctly (if applicable)

## Security Considerations
Describe any security implications, CVE fixes, or hardening improvements.

## Screenshots / Logs (if applicable)
Include relevant build output, scan results, or runtime logs.

## Checklist
- [ ] Code follows project style guidelines
- [ ] Commits follow semantic commit format
- [ ] Documentation updated (if needed)
- [ ] Tests pass locally
- [ ] No new HIGH/CRITICAL vulnerabilities introduced
- [ ] CHANGELOG.md updated (for notable changes)
```

### PR Labels

Labels are automatically assigned based on PR title, but can be manually adjusted:

| Label | Purpose |
|-------|---------|
| `enhancement` | New features or capabilities |
| `bug` | Bug fixes |
| `documentation` | Documentation updates |
| `dependencies` | Dependency updates |
| `security` | Security-related changes |
| `ci` | CI/CD workflow changes |
| `breaking` | Breaking changes requiring major version bump |

### Draft PRs

Use draft PRs for work-in-progress contributions:

```bash
# Open PR as draft
gh pr create --draft --title "feat(chainguard): add jdk26 support" --body "WIP: Testing build configuration"

# Mark ready for review when complete
gh pr ready
```

Draft PRs:
- Allow early feedback on approach
- Run CI checks without requiring approval
- Can be converted to ready when complete

## Code Review Process

All PRs require review and approval before merging to maintain code quality and security standards.

### Review Checklist

Reviewers evaluate the following aspects:

**Code Quality**:
- [ ] Code follows project conventions and style
- [ ] Dockerfiles use multi-stage builds effectively
- [ ] Scripts include error handling and validation
- [ ] Changes are well-documented with comments where needed

**Testing**:
- [ ] All CI checks pass (build, scan, lint)
- [ ] Manual testing performed and documented
- [ ] No new HIGH/CRITICAL vulnerabilities introduced
- [ ] SBOM generation succeeds

**Documentation**:
- [ ] README updated if user-facing changes
- [ ] Inline comments explain complex logic
- [ ] CHANGELOG.md updated for notable changes
- [ ] Commit messages are clear and descriptive

**Architecture**:
- [ ] Changes align with project patterns
- [ ] No unnecessary complexity introduced
- [ ] Security best practices followed
- [ ] Multi-architecture compatibility maintained

**Security**:
- [ ] Base images remain digest-pinned
- [ ] No secrets or credentials committed
- [ ] Download URLs use HTTPS with retry logic
- [ ] SHA256 verification for all downloads

### Providing Feedback

**For Reviewers**:
- Be constructive and specific in comments
- Suggest alternatives rather than just pointing out issues
- Distinguish between required changes and suggestions
- Approve when all blocking issues are resolved

**For Contributors**:
- Address all review comments
- Push additional commits to the same branch (don't force-push)
- Mark conversations as resolved when addressed
- Request re-review when ready

### Review Response Examples

```markdown
# Requesting changes
The musl fallback logic looks good, but I'm concerned about error handling if both musl and glibc downloads fail. Can we add explicit error messages for that case?

# Approving with suggestions
LGTM! One optional suggestion: consider extracting the arch mapping logic to a separate function for reusability. Not blocking for this PR.

# Blocking on security concern
Please update the base image digest - the current one has a HIGH severity CVE. See Trivy scan output.
```

## Testing Requirements

Comprehensive testing ensures reliability and security of published images.

### Local Testing Workflow

**1. Syntax Validation**:
```bash
# Lint all Dockerfiles
make lint

# Check specific Dockerfile
hadolint images/chainguard/Dockerfile.jdk25

# Validate shell scripts
shellcheck scripts/*.sh
```

**2. Build Testing**:
```bash
# Build single-platform image for quick iteration
make build TYPE=chainguard FLAVOR=jdk25

# Build specific target from Bake file
docker buildx bake chainguard-jdk25 --set *.args.SOURCE_DATE_EPOCH=$(date +%s)

# Build multi-arch (slower, requires emulation)
docker buildx bake chainguard-jdk25 --set *.args.SOURCE_DATE_EPOCH=$(date +%s) --platform linux/amd64,linux/arm64
```

**3. SBOM and Scanning**:
```bash
# Generate SBOM
make sbom TYPE=chainguard FLAVOR=jdk25

# Inspect SBOM contents
cat sbom/chainguard-jdk25.cdx.json | jq '.components[] | {name, version}'

# Run vulnerability scans (must pass for PR approval)
make scan TYPE=chainguard FLAVOR=jdk25

# Scan specific image
trivy image --severity HIGH,CRITICAL ghcr.io/artagon/artagon-containers:chainguard-jdk25
grype ghcr.io/artagon/artagon-containers:chainguard-jdk25
```

**4. Runtime Testing**:
```bash
# Basic functionality test
docker run --rm ghcr.io/artagon/artagon-containers:chainguard-jdk25 java --version

# Test with security hardening
docker run --rm \
  --read-only \
  --tmpfs /tmp:rw,exec,nosuid,nodev \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25 \
  java -XshowSettings:vm -version

# Test with sample application
docker run --rm \
  -v "$(pwd)/test:/workspace:ro" \
  ghcr.io/artagon/artagon-containers:chainguard-jdk25 \
  java -jar /workspace/HelloWorld.jar

# Test distroless JRE with module system
docker run --rm \
  ghcr.io/artagon/artagon-containers:distroless-jre26ea \
  java --list-modules
```

**5. JDK Resolution Testing**:
```bash
# Test metadata resolution for JDK 25 GA
./scripts/resolve_jdk.sh --flavor=jdk25 --arch=amd64 --libc=glibc --type=chainguard

# Test JDK 26 EA resolution
./scripts/resolve_jdk.sh --flavor=jdk26ea --arch=arm64 --libc=musl --type=distroless

# Test Valhalla resolution
./scripts/resolve_jdk.sh --flavor=jdk26valhalla --arch=amd64 --libc=glibc --type=ubi9

# Save resolved metadata to file
mkdir -p .env
./scripts/resolve_jdk.sh --flavor=jdk25 --arch=amd64 --libc=glibc --type=chainguard --output=.env/test.env
cat .env/test.env
```

### Coverage Targets

**Build Coverage**:
- All 15 image targets must build successfully
- Both amd64 and arm64 architectures must build
- All glibc and musl libc variants must build

**Security Coverage**:
- Zero HIGH or CRITICAL CVEs in published images
- All base images must be digest-pinned
- All downloads must have SHA256 verification
- Cosign signatures must verify successfully

**Functional Coverage**:
- `java --version` must execute successfully
- JVM settings must be container-aware
- Read-only rootfs must be supported
- Non-root execution must work correctly

### CI/CD Testing

**Pull Request Checks**:
- Builds all 15 targets for linux/amd64
- Generates SBOMs for all targets
- Runs Trivy and Grype scans
- Fails on HIGH/CRITICAL CVEs
- Does not push images (load only)

**Main Branch Builds**:
- Builds for linux/amd64 and linux/arm64
- Pushes multi-arch manifests to GHCR
- Signs images with Cosign keyless
- Attests SBOMs with Cosign

**Release Workflow**:
- Triggered by semantic version tags (v1.2.3)
- Builds and signs all images
- Generates release notes from commits
- Uploads SBOM artifacts to GitHub Release

**Nightly Scans**:
- Re-scans all published images
- Creates GitHub issues for new CVEs
- Labels issues by severity and base type

## Documentation Updates

Documentation must be kept in sync with code changes to ensure accuracy.

### When to Update Documentation

Update documentation when:
- **Adding features**: New image variants, build targets, or capabilities
- **Changing APIs**: Makefile targets, script interfaces, or workflow inputs
- **Fixing documented behavior**: Bugs that contradict existing documentation
- **Introducing new scripts**: Build automation or tooling
- **Modifying workflows**: CI/CD pipeline changes
- **Updating dependencies**: Version bumps affecting user experience

### Documentation Files

| File | Purpose | Update Triggers |
|------|---------|----------------|
| `README.md` | Main project documentation | Image variants, usage examples, verification steps |
| `CHANGELOG.md` | Version history and changes | All user-facing changes, bug fixes, new features |
| `openspec/project.md` | Detailed project context | Architecture changes, new constraints, dependency updates |
| `openspec/contributing.md` | This file | Workflow changes, new tooling, convention updates |
| `images/*/README.md` | Base-specific documentation | Image-specific changes, usage notes, licenses |
| `policy/SECURITY.md` | Security policy and guidance | Supported tags, reporting process, hardening guidance |
| `policy/SUPPLY-CHAIN.md` | Supply chain controls | Signing process, SBOM format, scanning gates |

### Documentation Style

**Technical Writing Best Practices**:
- Use clear, concise language
- Write in present tense ("the script resolves" not "the script will resolve")
- Use active voice ("run the command" not "the command should be run")
- Include working code examples that can be copy-pasted
- Format commands as code blocks with syntax highlighting
- Use tables for structured comparisons
- Add headings for easy navigation

**Code Block Format**:
````markdown
```bash
# Comment explaining what this does
make build TYPE=chainguard FLAVOR=jdk25
```
````

**Command Examples**:
- Include comments explaining each flag
- Show expected output when helpful
- Demonstrate error cases and how to resolve them
- Use realistic values, not placeholders like "YOUR_VALUE_HERE"

**Cross-References**:
- Link to related documentation sections
- Reference specific files with line numbers when applicable
- Include URLs to external resources (Adoptium API, Cosign docs, etc.)

### Changelog Format

Follow "Keep a Changelog" conventions:

```markdown
# Changelog

## [Unreleased]
### Added
- New distroless musl variants for JDK 26 Valhalla

### Fixed
- Musl fallback logic in resolve_jdk.sh

## [0.1.0] - 2025-01-04
### Added
- Initial publication of Chainguard, Distroless, and UBI images
- Multi-arch support for linux/amd64 and linux/arm64
- SBOM generation with Syft CycloneDX format
- Cosign keyless signing and SLSA provenance

### Security
- Digest-pinned base images for supply chain security
- Trivy/Grype scanning with HIGH/CRITICAL gates
```

## Code Style Standards

Consistent code style improves readability and reduces cognitive load during reviews.

### Shell Scripts

**General Rules**:
- Use `#!/usr/bin/env bash` shebang
- Add `set -euo pipefail` immediately after shebang
- Use 2-space indentation
- Quote all variable references: `"${VAR}"` not `$VAR`
- Use `[[ ]]` for conditionals, not `[ ]`
- Include usage function and --help flag

**Example**:
```bash
#!/usr/bin/env bash
set -euo pipefail

FLAVOR="jdk25"
ARCH="amd64"

usage() {
  cat <<'USAGE'
resolve_jdk.sh --flavor=<jdk25|jdk26ea> --arch=<amd64|arm64>
Resolves JDK download URL and SHA256 checksum.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --flavor=*) FLAVOR="${arg#*=}" ;;
    --arch=*) ARCH="${arg#*=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
  echo "Unsupported arch: $ARCH" >&2
  exit 1
fi

echo "Resolving JDK ${FLAVOR} for ${ARCH}..."
```

**Shellcheck Integration**:
```bash
# Run shellcheck on all scripts
shellcheck scripts/*.sh

# Fix common issues automatically (if using shfmt)
shfmt -w -i 2 scripts/*.sh
```

### Dockerfiles

**General Rules**:
- Use official `syntax=docker/dockerfile:1.7` parser directive
- Multi-stage builds with descriptive stage names (`AS builder`, `AS runtime`)
- Combine RUN commands to minimize layers: `RUN cmd1 && cmd2`
- Pin base images by digest
- Use `ARG` for build-time configuration
- Use `ENV` for runtime configuration
- Set `WORKDIR`, `USER`, and labels explicitly
- Add `ENTRYPOINT` and `CMD` for default behavior

**Example**:
```dockerfile
# syntax=docker/dockerfile:1.7
ARG BASE_DIGEST="sha256:abc123..."
FROM cgr.dev/chainguard/wolfi-base:latest@${BASE_DIGEST} AS builder

ARG FLAVOR=jdk25
ARG TARGETARCH

RUN apk add --no-cache curl bash python3 && \
    curl -fsSL https://example.com/jdk.tar.gz -o /tmp/jdk.tar.gz && \
    tar -xzf /tmp/jdk.tar.gz -C /opt/jdk --strip-components=1 && \
    rm -f /tmp/jdk.tar.gz

FROM cgr.dev/chainguard/wolfi-base:latest@${BASE_DIGEST}

ARG FLAVOR=jdk25
ENV JAVA_HOME=/usr/lib/jvm/jdk-${FLAVOR}
ENV PATH="${JAVA_HOME}/bin:${PATH}"

COPY --from=builder /opt/jdk /usr/lib/jvm/jdk-${FLAVOR}

WORKDIR /workspace
USER 65532:65532

LABEL org.opencontainers.image.title="artagon-chainguard-${FLAVOR}" \
      org.opencontainers.image.source="https://github.com/artagon/artagon-containers" \
      org.opencontainers.image.licenses="GPL-2.0-with-classpath-exception"

ENTRYPOINT ["java"]
CMD ["--version"]
```

**Hadolint Integration**:
```bash
# Lint all Dockerfiles
hadolint images/*/Dockerfile.*

# Ignore specific rules inline
# hadolint ignore=DL3018
RUN apk add --no-cache curl
```

### Docker Bake HCL

**General Rules**:
- Use descriptive target names matching image tags
- Define common attributes in `target "common"`
- Use variables for registry and configurable values
- Inherit from common target to reduce duplication
- Group related targets with `group` directive

**Example**:
```hcl
variable "REGISTRY" {
  default = "ghcr.io/artagon/artagon-containers"
}

target "common" {
  context = "."
  platforms = ["linux/amd64", "linux/arm64"]
  args = {
    SOURCE_DATE_EPOCH = SOURCE_DATE_EPOCH
  }
}

target "chainguard-jdk25" {
  inherits = ["common"]
  dockerfile = "images/chainguard/Dockerfile.jdk25"
  args = {
    FLAVOR = "jdk25"
    LIBC = "musl"
  }
  tags = ["${REGISTRY}:chainguard-jdk25"]
}
```

## Git Hooks

Git hooks automate quality checks during the development workflow.

### Pre-Commit Hook

Create `.git/hooks/pre-commit` and make it executable:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Running pre-commit checks..."

# Validate commit message format (if using prepare-commit-msg)
# Shellcheck validation
if command -v shellcheck &> /dev/null; then
  echo "Running shellcheck..."
  shellcheck scripts/*.sh || { echo "Shellcheck failed"; exit 1; }
fi

# Hadolint validation
if command -v hadolint &> /dev/null; then
  echo "Running hadolint..."
  hadolint images/*/Dockerfile.* || { echo "Hadolint failed"; exit 1; }
fi

echo "Pre-commit checks passed ✓"
```

### Commit-Msg Hook

Validate semantic commit format. Create `.git/hooks/commit-msg`:

```bash
#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Regex for semantic commit format
PATTERN="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([a-z0-9-]+\))?: .{1,50}"

if ! echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
  echo "Error: Commit message does not follow semantic commit format"
  echo "Expected: <type>(<scope>): <subject>"
  echo "Example: feat(chainguard): add jdk26 support"
  exit 1
fi

echo "Commit message format valid ✓"
```

### Pre-Push Hook

Run quick validation before pushing. Create `.git/hooks/pre-push`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Running pre-push checks..."

# Ensure no uncommitted changes
if ! git diff-index --quiet HEAD --; then
  echo "Error: Uncommitted changes detected"
  exit 1
fi

# Run linting
make lint || { echo "Linting failed"; exit 1; }

echo "Pre-push checks passed ✓"
```

### Installing Hooks

```bash
# Make hooks executable
chmod +x .git/hooks/pre-commit .git/hooks/commit-msg .git/hooks/pre-push

# Optional: Use a setup script
cat > scripts/setup-hooks.sh <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

HOOKS_DIR=".git/hooks"
mkdir -p "$HOOKS_DIR"

# Install hooks from repository
cp -f scripts/hooks/* "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR"/*

echo "Git hooks installed successfully"
SCRIPT

chmod +x scripts/setup-hooks.sh
./scripts/setup-hooks.sh
```

## Merging Strategy

Maintainers use consistent merge strategies to preserve history and maintain a clean commit log.

### Merge Types

**Squash Merge** (default for most PRs):
- Combines all PR commits into a single commit
- Useful for feature branches with many incremental commits
- Preserves semantic commit message from PR title
- Loses individual commit history from PR

```bash
# Squash merge via GitHub UI
# OR via gh CLI:
gh pr merge 42 --squash --delete-branch
```

**Merge Commit** (for multi-commit features):
- Preserves all individual commits from PR
- Creates a merge commit linking to PR
- Use when commits are well-structured and meaningful
- Useful for large features with logical progression

```bash
# Merge commit via GitHub UI
# OR via gh CLI:
gh pr merge 42 --merge --delete-branch
```

**Rebase and Merge** (rarely used):
- Replays commits onto main without merge commit
- Creates linear history
- Only use for clean, well-tested commit sequences

### Branch Cleanup

- Feature branches are automatically deleted after merge
- Contributors should delete their fork branches manually
- Keep `main` clean with no stale branches

```bash
# Delete local branch after merge
git branch -d feat/42-add-jdk26-support

# Delete remote branch on your fork
git push origin --delete feat/42-add-jdk26-support

# Sync your fork with upstream
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

### Auto-Closing Issues

Issues are automatically closed when:
- Commit message includes "Closes #N" in body or footer
- PR description includes "Closes #N"
- PR is merged to main branch

**Examples**:
```bash
# In commit message
git commit -m "feat(chainguard): add jdk26 support

Implements JDK 26 EA builds using Artagon tap.

Closes #42"

# In PR description (via gh CLI)
gh pr create --title "feat(chainguard): add jdk26 support" --body "Closes #42"
```

## Summary

This contributing guide covers the complete development workflow for Artagon Containers:

1. **Setup**: Install prerequisites and clone repository
2. **Issues**: Create or reference issues for all work
3. **Branches**: Follow naming convention with issue numbers
4. **Commits**: Use semantic commit format consistently
5. **Testing**: Run local builds, scans, and runtime tests
6. **PRs**: Submit well-documented pull requests with passing CI
7. **Review**: Respond to feedback and iterate on changes
8. **Merge**: Maintainers merge with appropriate strategy

For questions or assistance, please:
- Open a GitHub issue for bugs or feature requests
- Reference this guide for workflow questions
- Review existing PRs for examples
- Consult project documentation in `openspec/` directory

Thank you for contributing to Artagon Containers!
