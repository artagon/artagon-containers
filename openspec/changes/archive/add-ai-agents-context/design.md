# Design: AI Agents Context Integration

## Overview

This document describes the architecture for integrating AI agents with the artagon-containers project. Content is centralized in `docs/ai/` (2 files only) with symbolic links enabling discovery by multiple AI tools.

## Architecture

### Centralized Content with Symlink Discovery

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Tool Discovery Layer                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Root Symlinks:                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │AGENTS.md │  │CLAUDE.md │  │COPILOT.md│  │GEMINI.md │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │             │             │          │
│       └─────────────┴──────┬──────┴─────────────┘          │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              docs/ai/AGENTS.md                       │   │
│  │    (Single Source + Implementation Guidance)         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    GitHub Copilot Layer                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  .github/ Symlinks:                                         │
│  ┌──────────────────────────┐  ┌─────────────────────────┐ │
│  │copilot-instructions.md   │  │copilot-review-instr...  │ │
│  └───────────┬──────────────┘  └───────────┬─────────────┘ │
│              │                             │               │
│              ▼                             ▼               │
│  ┌──────────────────────────┐  ┌─────────────────────────┐ │
│  │   docs/ai/AGENTS.md      │  │docs/ai/review-          │ │
│  │                          │  │instructions.md          │ │
│  └──────────────────────────┘  └─────────────────────────┘ │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    OpenSpec Workflow                         │
├─────────────────────────────────────────────────────────────┤
│  openspec/                                                  │
│  ├── AGENTS.md                  # Authoritative workflow    │
│  ├── project.md                 # Project conventions       │
│  ├── contributing.md            # Contribution guidelines   │
│  ├── specs/                     # Capability specifications │
│  └── changes/                   # Active change proposals   │
└─────────────────────────────────────────────────────────────┘
```

### File Relationships

```
docs/ai/
├── AGENTS.md                    ◄─── AGENTS.md (symlink)
│                                ◄─── CLAUDE.md (symlink)
│                                ◄─── COPILOT.md (symlink)
│                                ◄─── GEMINI.md (symlink)
│                                ◄─── .github/copilot-instructions.md (symlink)
│
└── review-instructions.md       ◄─── .github/copilot-review-instructions.md (symlink)
```

### AI Tool Discovery Mechanisms

| AI Tool | Discovery Path | Target |
|---------|----------------|--------|
| Claude Code | `CLAUDE.md` (root) | `docs/ai/AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md` | `docs/ai/AGENTS.md` |
| GitHub Copilot Review | `.github/copilot-review-instructions.md` | `docs/ai/review-instructions.md` |
| Gemini | `GEMINI.md` (root) | `docs/ai/AGENTS.md` |
| Generic LLM | `AGENTS.md` (root) | `docs/ai/AGENTS.md` |

## Component Design

### 1. Main AI Instructions (`docs/ai/AGENTS.md`)

**Purpose**: Single source of truth for AI assistant context, including implementation guidance.

**Content Structure**:
```markdown
# AI Agent Instructions

This repository uses OpenSpec for spec-driven development.

## Quick Reference
- OpenSpec workflow: `openspec/AGENTS.md`
- Project conventions: `openspec/project.md`
- Active changes: `openspec/changes/`

## Key Directories
- `images/`: Container image Dockerfiles
- `scripts/`: Build and automation scripts
- `security/`: Seccomp and AppArmor profiles
- `policy/`: Security and supply chain policies
- `openspec/`: Spec-driven workflow

## Container Build Patterns
- Multi-stage builds with digest-pinned bases
- Non-root user (UID 65532)
- Security hardening conventions

## Implementation Guidelines

Core rules:
- Specs in GitHub Issues (label: `spec`) and `openspec/changes/`
- Built behavior in `openspec/specs/`
- Link every implementation PR to its parent spec issue

Before you code:
1. Run `openspec list` to identify active change
2. Read `openspec/changes/<id>/proposal.md` and `tasks.md`
3. Read spec deltas and base spec
4. Follow conventions in `openspec/project.md`

Implementation expectations:
- Keep changes scoped to spec
- Update tasks.md as items complete
- Maintain digest-pinned base images
- Preserve non-root user conventions

## For Reviews
See `docs/ai/review-instructions.md`
```

### 2. Review Instructions (`docs/ai/review-instructions.md`)

**Purpose**: Guide AI tools during code review tasks.

**Compliance Rating Scale**:
- **Full**: All acceptance criteria met with tests
- **Partial**: Most criteria met, gaps listed
- **Minimal**: Small subset met
- **None**: No alignment with spec

**Structured Review Format**:
```
Spec Reference: <issue link or "missing">
OpenSpec Change: <change-id or "unknown">
Compliance Rating: <full|partial|minimal|none>

Acceptance Criteria Coverage:
- [ ] Item 1 ... (status)

Scope Creep:
- <list out-of-scope changes>

Missing Tests:
- <list missing tests>

Breaking Changes:
- <list and confirm coverage>
```

### 3. Label Taxonomy (`labels.yml`)

**OpenSpec Labels**:
| Label | Color | Purpose |
|-------|-------|---------|
| `spec` | Green (#0E8A16) | Specification issues |
| `proposal` | Blue (#1D76DB) | Proposal documents |
| `implementation` | Purple (#5319E7) | Implementation PRs |
| `spec:draft` | Yellow (#FBCA04) | Work in progress |
| `spec:approved` | Green (#0E8A16) | Ready for implementation |
| `spec:implemented` | Dark Green (#0B5345) | Fully deployed |
| `needs-spec` | Orange (#D93F0B) | PR missing spec reference |
| `scope-creep` | Red (#B60205) | Out-of-scope changes |

**Preserved Labels**:
- `bug` - Bug reports
- `enhancement` - Feature requests
- `security` - Security issues
- `vulnerability` - CVE findings

### 4. Issue Templates

**Spec Template (`spec.yml`)**:
- YAML form format for structured capture
- Required: Summary, Motivation, Detailed Design, Acceptance Criteria
- Optional: Out of Scope, Open Questions, Related Issues
- Auto-labels: `spec`, `spec:draft`

**Proposal Template (`proposal.yml`)**:
- YAML form format
- Required: Related Spec, Proposed Approach, Implementation Plan
- Optional: Alternatives, Trade-offs, Risks
- Auto-label: `proposal`

### 5. PR Template

**Sections**:
1. Type of change (checkbox selection)
2. Spec/proposal reference (required for implementations)
3. Summary of changes
4. Spec compliance checklist
5. Testing checklist
6. Breaking changes

## Symlink Implementation

### Creating Symlinks

```bash
# Create docs/ai directory
mkdir -p docs/ai

# Create content files in docs/ai/
# (AGENTS.md, review-instructions.md)

# Create root symlinks
ln -s docs/ai/AGENTS.md AGENTS.md
ln -s docs/ai/AGENTS.md CLAUDE.md
ln -s docs/ai/AGENTS.md COPILOT.md
ln -s docs/ai/AGENTS.md GEMINI.md

# Create .github symlinks
ln -s ../docs/ai/AGENTS.md .github/copilot-instructions.md
ln -s ../docs/ai/review-instructions.md .github/copilot-review-instructions.md
```

### Git Symlink Handling

Git tracks symlinks as special file entries containing the target path:
- Works on Linux, macOS, and Windows (with `core.symlinks=true`)
- Symlinks are stored in the repository, not dereferenced
- Clone/checkout recreates symlinks on supported platforms

### Platform Considerations

| Platform | Symlink Support | Notes |
|----------|-----------------|-------|
| Linux | Full | Native support |
| macOS | Full | Native support |
| Windows | Conditional | Requires Developer Mode or admin privileges |

For Windows users without symlink support, Git can be configured to create copies instead with `core.symlinks=false`.

## Integration Points

### With Existing CLAUDE.md

The current `CLAUDE.md` contains OpenSpec instructions. After migration:
1. Content moves to `docs/ai/AGENTS.md`
2. `CLAUDE.md` becomes symlink to `docs/ai/AGENTS.md`
3. Claude Code continues to find instructions via `CLAUDE.md`

### With OpenSpec Workflow

All documentation references:
- `openspec/AGENTS.md` - Authoritative workflow details
- `openspec/project.md` - Project conventions
- `openspec/contributing.md` - Contribution guidelines

The `docs/ai/AGENTS.md` provides a summary and links to these files.

### With GitHub Features

- **Issues**: Spec and proposal templates auto-label on creation
- **PRs**: Template enforces spec reference for implementations
- **Labels**: Enable filtering, sorting, and automation triggers
- **Copilot**: Discovers instructions via `.github/` symlinks

## Security Considerations

- No secrets or credentials in AI context files
- Templates do not expose internal details
- AI instructions are public and auditable
- Symlinks do not elevate permissions

## Future Extensions

1. **Automated Compliance Workflow**: GitHub Action to validate spec references
2. **Spec Review Reminder**: Automated issue creation when specs are approved
3. **Label Sync Action**: Ensure labels.yml is applied to repository
4. **Content Validation**: CI check that symlinks resolve correctly
