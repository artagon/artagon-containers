# Proposal: Add AI Agents Context Integration

## Summary

Add comprehensive AI agents context integration to artagon-containers. Content is centralized in `docs/ai/` with symbolic links for AI tool discovery.

## Motivation

The artagon-containers project already has Claude Code integration via `.claude/` configuration and OpenSpec workflow. However, it lacks:

1. **GitHub Copilot integration** - No guidance for Copilot to understand OpenSpec workflow
2. **PR template with spec compliance** - Current templates don't enforce spec references
3. **OpenSpec issue templates** - No structured templates for spec/proposal creation
4. **Label taxonomy** - Missing labels for spec lifecycle tracking (`spec:draft`, `spec:approved`, `spec:implemented`, `needs-spec`, `scope-creep`)
5. **Multi-AI entry points** - No `COPILOT.md` or `GEMINI.md` for other AI assistants

This gap means AI assistants other than Claude may not follow OpenSpec conventions, leading to scope creep, missing spec references, and inconsistent reviews.

## Goals

- Centralize AI context documentation in `docs/ai/`
- Enable GitHub Copilot to follow OpenSpec workflow conventions
- Enforce spec references in implementation PRs through templates
- Provide structured issue templates for spec and proposal creation
- Create consistent label taxonomy for spec lifecycle tracking
- Support multiple AI assistants with symbolic links to centralized content

## Non-Goals

- Automated spec compliance workflows (future work)
- Agent-specific context directories (not applicable to container builds)
- Spec validation scripts (can be added later)

## Proposed Changes

### 1. Centralized AI Context (`docs/ai/`)

Create `docs/ai/` directory with two authoritative files:

**`docs/ai/AGENTS.md`** - Main AI agent instructions (includes implementation guidance):
- OpenSpec workflow overview
- Key directories (`images/`, `scripts/`, `security/`, `policy/`)
- Container build patterns and conventions
- Implementation expectations and good/bad patterns
- Links to review instructions

**`docs/ai/review-instructions.md`** - Review guidance:
- Spec compliance review checklist
- Structured review format template
- Compliance rating definitions (Full/Partial/Minimal/None)

### 2. Root-Level Symbolic Links

Create symlinks at repository root for AI tool discovery:

```
AGENTS.md    → docs/ai/AGENTS.md
CLAUDE.md    → docs/ai/AGENTS.md
COPILOT.md   → docs/ai/AGENTS.md
GEMINI.md    → docs/ai/AGENTS.md
```

All AI assistants discover the same authoritative content.

### 3. GitHub Configuration Symbolic Links

Create symlinks in `.github/` for GitHub Copilot:

```
.github/copilot-instructions.md        → ../docs/ai/AGENTS.md
.github/copilot-review-instructions.md → ../docs/ai/review-instructions.md
```

### 4. OpenSpec Issue Templates

Add `.github/ISSUE_TEMPLATE/spec.yml`:
- Summary, motivation, detailed design sections
- Acceptance criteria checklist
- Out of scope and open questions fields
- Auto-labels: `spec`, `spec:draft`

Add `.github/ISSUE_TEMPLATE/proposal.yml`:
- Related spec reference (required)
- Proposed approach and alternatives
- Trade-offs and risks
- Auto-label: `proposal`

### 5. PR Template

Create `.github/PULL_REQUEST_TEMPLATE.md` with OpenSpec-aware template:
- Type selection (Spec, Proposal, Implementation, Fix)
- Spec reference section (required for implementations)
- Compliance checklist
- Breaking changes section

### 6. Label Taxonomy

Create `.github/labels.yml` with OpenSpec labels:
- `spec` - Specification issues
- `proposal` - Proposal documents
- `implementation` - Implementation PRs
- `spec:draft` - Work in progress specs
- `spec:approved` - Ready for implementation
- `spec:implemented` - Fully deployed specs
- `needs-spec` - PR missing spec reference
- `scope-creep` - Changes beyond spec scope

Preserve existing labels: `bug`, `enhancement`, `security`, `vulnerability`

## File Structure

```
docs/ai/                                    # Centralized AI context
├── AGENTS.md                               # Main AI instructions + implementation guidance
└── review-instructions.md                  # Review guidance

AGENTS.md   → docs/ai/AGENTS.md             # Symlink
CLAUDE.md   → docs/ai/AGENTS.md             # Symlink
COPILOT.md  → docs/ai/AGENTS.md             # Symlink
GEMINI.md   → docs/ai/AGENTS.md             # Symlink

.github/
├── copilot-instructions.md → ../docs/ai/AGENTS.md                  # Symlink
├── copilot-review-instructions.md → ../docs/ai/review-instructions.md  # Symlink
├── labels.yml                              # Label definitions
├── PULL_REQUEST_TEMPLATE.md                # PR template
└── ISSUE_TEMPLATE/
    ├── spec.yml                            # Spec issue template
    ├── proposal.yml                        # Proposal issue template
    ├── bug.md                              # Existing bug template
    └── feature.md                          # Existing feature template
```

## Impact Assessment

### Affected Areas
- `docs/ai/` directory (new)
- `.github/` directory (new files, symlinks)
- Root directory (new symlinks)

### Risk Assessment
- **Low risk**: All changes are additive configuration
- **No breaking changes**: Existing workflows continue to work
- **Rollback**: Simply delete added files/symlinks if issues arise
- **Symlink compatibility**: Git tracks symlinks correctly on all platforms

## Alternatives Considered

### 1. Separate files for each AI tool
Maintain independent AGENTS.md, CLAUDE.md, COPILOT.md with duplicated content.

**Rejected**: Content duplication leads to drift and maintenance burden.

### 2. Full artagon-site approach (with `.agents/` directory)
Include `.agents/` directory with manifests, workflows, and context files.

**Rejected**: The `.agents/` structure is tailored for web development. Container builds have different patterns.

### 3. Three separate instruction files
Have AGENTS.md, copilot-instructions.md, and review-instructions.md as separate files.

**Rejected**: Unnecessary duplication. AGENTS.md can contain implementation guidance directly.

## Success Criteria

1. Single source of truth for AI context in `docs/ai/` (2 files only)
2. All AI tools (Claude, Copilot, Gemini) discover consistent guidance
3. GitHub Copilot understands OpenSpec workflow
4. New PRs use spec compliance template
5. Spec and proposal issues use structured templates
6. Labels enable filtering and tracking spec lifecycle
