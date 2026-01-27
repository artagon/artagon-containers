# AI Agents Context

Provides centralized configuration and documentation for AI assistants in `docs/ai/` (2 files) with symbolic links for multi-tool discovery.

## ADDED Requirements

### Requirement: Centralized AI Context

The repository SHALL maintain AI context documentation in `docs/ai/` as the single source of truth with only two files.

#### Scenario: AI documentation is centralized

**Given** the repository contains AI context files
**When** a maintainer needs to update AI instructions
**Then** they edit files in `docs/ai/` only
**And** all AI tools receive the updated content via symlinks

#### Scenario: docs/ai structure is minimal

**Given** the `docs/ai/` directory exists
**When** listing its contents
**Then** it contains exactly two files:
- `AGENTS.md` with main instructions and implementation guidance
- `review-instructions.md` with review guidance

---

### Requirement: Root-Level Symbolic Links

The repository SHALL provide symbolic links at the root level pointing to `docs/ai/AGENTS.md` for AI tool discovery.

#### Scenario: Claude discovers context via CLAUDE.md

**Given** Claude Code is activated in the repository
**When** Claude reads `CLAUDE.md`
**Then** it resolves to `docs/ai/AGENTS.md`
**And** finds OpenSpec workflow and implementation instructions

#### Scenario: Copilot discovers context via COPILOT.md

**Given** GitHub Copilot is activated in the repository
**When** Copilot reads `COPILOT.md`
**Then** it resolves to `docs/ai/AGENTS.md`
**And** finds project context, key directories, and implementation guidance

#### Scenario: Gemini discovers context via GEMINI.md

**Given** Gemini is activated in the repository
**When** Gemini reads `GEMINI.md`
**Then** it resolves to `docs/ai/AGENTS.md`
**And** can follow OpenSpec workflow conventions

#### Scenario: Generic AI discovers context via AGENTS.md

**Given** any AI tool looks for project instructions
**When** it reads `AGENTS.md` at repository root
**Then** it resolves to `docs/ai/AGENTS.md`
**And** receives consistent guidance

---

### Requirement: GitHub Copilot Symbolic Links

The `.github/` directory SHALL provide symbolic links to `docs/ai/` for GitHub Copilot discovery.

#### Scenario: Copilot finds implementation instructions

**Given** GitHub Copilot assists with implementation
**When** it reads `.github/copilot-instructions.md`
**Then** it resolves to `docs/ai/AGENTS.md`
**And** understands container build patterns and OpenSpec workflow

#### Scenario: Copilot finds review instructions

**Given** GitHub Copilot assists with code review
**When** it reads `.github/copilot-review-instructions.md`
**Then** it resolves to `docs/ai/review-instructions.md`
**And** uses the structured review format with compliance ratings

---

### Requirement: OpenSpec Label Taxonomy

The repository SHALL define labels in `.github/labels.yml` to enable tracking of spec lifecycle and compliance status.

#### Scenario: New spec issue is created

**Given** a contributor opens an issue using the spec template
**When** the issue is submitted
**Then** it receives labels `spec` and `spec:draft`
**And** appears in filtered views for spec review

#### Scenario: Spec is approved

**Given** a `spec:draft` issue has been reviewed
**When** the maintainer approves the spec
**Then** the `spec:draft` label is removed
**And** the `spec:approved` label is added
**And** implementation can begin

#### Scenario: Implementation PR lacks spec reference

**Given** an implementation PR is opened
**When** no spec issue is referenced
**Then** the `needs-spec` label can be applied
**And** the PR is flagged for attention

#### Scenario: Out-of-scope changes detected

**Given** an implementation PR includes changes not in the spec
**When** a reviewer identifies scope creep
**Then** the `scope-creep` label can be applied
**And** the reviewer notes the specific out-of-scope changes

---

### Requirement: OpenSpec Issue Templates

The repository SHALL provide structured YAML form templates for spec and proposal creation with consistent fields.

#### Scenario: Creating a spec issue

**Given** a contributor wants to define new capability
**When** they select the "Spec" issue template
**Then** they see a form with sections:
- Summary (required)
- Motivation (required)
- Detailed Design (required)
- Acceptance Criteria (required)
- Out of Scope (optional)
- Open Questions (optional)
- Related Issues/Specs (optional)

#### Scenario: Creating a proposal issue

**Given** a contributor wants to propose implementation approach
**When** they select the "Proposal" issue template
**Then** they see a form with sections:
- Related Spec (required)
- Proposed Approach (required)
- Alternatives Considered (optional)
- Trade-offs (optional)
- Implementation Plan (required)
- Risks and Mitigations (optional)

---

### Requirement: OpenSpec PR Template

The repository SHALL provide a PR template that enforces spec compliance for implementation changes.

#### Scenario: Opening implementation PR

**Given** a developer opens a PR implementing a spec
**When** they fill out the PR template
**Then** they must select "Implementation" as change type
**And** reference the spec issue number
**And** reference the OpenSpec change directory
**And** acknowledge the compliance checklist

#### Scenario: Opening non-implementation PR

**Given** a developer opens a fix or docs PR
**When** they fill out the PR template
**Then** they can select "Fix" or other type
**And** spec reference is optional
**And** relevant checklists are still completed

---

## Related Capabilities

- **security-hardening**: AI guidance references security profiles and hardening conventions
- **container-runtime**: AI guidance documents container build patterns
