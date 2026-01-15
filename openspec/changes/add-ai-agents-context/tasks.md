# Tasks: Add AI Agents Context Integration

## Overview

Add centralized AI context in `docs/ai/` (2 files only) with symbolic links, OpenSpec-aware templates, and label taxonomy.

## Prerequisites

- [x] Verify artagon-site integration patterns for reference
- [x] Confirm no conflicts with existing `.github/` configuration
- [x] Check existing CLAUDE.md content for migration

## Implementation Tasks

### Phase 1: Centralized AI Context (`docs/ai/`)

- [x] **1.1** Create `docs/ai/` directory

- [x] **1.2** Create `docs/ai/AGENTS.md` with main AI instructions
  - OpenSpec workflow overview
  - Key directories (`images/`, `scripts/`, `security/`, `policy/`)
  - Container build patterns
  - Implementation guidelines and expectations
  - Link to review instructions
  - Migrate relevant content from existing CLAUDE.md

- [x] **1.3** Create `docs/ai/review-instructions.md`
  - Spec compliance review steps
  - Compliance rating scale (Full/Partial/Minimal/None)
  - Structured review format template

### Phase 2: Root-Level Symbolic Links

- [x] **2.1** Remove existing `CLAUDE.md` file (backup content first)

- [x] **2.2** Create root symlinks to `docs/ai/AGENTS.md`
  ```bash
  ln -s docs/ai/AGENTS.md AGENTS.md
  ln -s docs/ai/AGENTS.md CLAUDE.md
  ln -s docs/ai/AGENTS.md COPILOT.md
  ln -s docs/ai/AGENTS.md GEMINI.md
  ```

- [x] **2.3** Verify symlinks resolve correctly
  ```bash
  cat CLAUDE.md  # Should show docs/ai/AGENTS.md content
  cat COPILOT.md # Should show docs/ai/AGENTS.md content
  ```

### Phase 3: GitHub Configuration Symbolic Links

- [x] **3.1** Create `.github/` symlinks to `docs/ai/`
  ```bash
  ln -s ../docs/ai/AGENTS.md .github/copilot-instructions.md
  ln -s ../docs/ai/review-instructions.md .github/copilot-review-instructions.md
  ```

- [x] **3.2** Verify `.github/` symlinks resolve correctly

### Phase 4: Issue Templates

- [x] **4.1** Create `.github/ISSUE_TEMPLATE/spec.yml`
  - YAML form format
  - Summary, Motivation, Detailed Design (required)
  - Acceptance Criteria (required)
  - Out of Scope, Open Questions (optional)
  - Auto-labels: spec, spec:draft

- [x] **4.2** Create `.github/ISSUE_TEMPLATE/proposal.yml`
  - YAML form format
  - Related Spec (required)
  - Proposed Approach, Implementation Plan (required)
  - Alternatives, Trade-offs, Risks (optional)
  - Auto-label: proposal

- [x] **4.3** Review existing bug.md and feature.md for label consistency
  - No breaking changes to existing templates

### Phase 5: PR Template

- [x] **5.1** Create `.github/PULL_REQUEST_TEMPLATE.md`
  - Type of change selection (Spec, Proposal, Implementation, Fix)
  - Spec/proposal reference section
  - Compliance checklist
  - Testing checklist
  - Breaking changes section

### Phase 6: Label Taxonomy

- [x] **6.1** Create `.github/labels.yml` with OpenSpec taxonomy
  - spec, proposal, implementation labels
  - spec:draft, spec:approved, spec:implemented lifecycle labels
  - needs-spec, scope-creep compliance labels
  - Preserve existing labels (bug, enhancement, security, vulnerability)

## Validation Tasks

- [x] **7.1** Verify all symlinks resolve correctly
  ```bash
  ls -la AGENTS.md CLAUDE.md COPILOT.md GEMINI.md
  ls -la .github/copilot-instructions.md .github/copilot-review-instructions.md
  ```

- [x] **7.2** Test symlinks work after git operations
  ```bash
  git status  # Symlinks should appear as new files
  ```

- [ ] **7.3** Test issue templates on GitHub
  - Create test spec issue, verify form fields
  - Create test proposal issue, verify spec reference
  - Delete test issues after verification

- [ ] **7.4** Test PR template
  - Open draft PR, verify template renders
  - Verify checklist items are present
  - Close draft PR after verification

- [ ] **7.5** Apply labels to repository
  ```bash
  gh label create spec --color 0E8A16 --description "Specification issues"
  gh label create proposal --color 1D76DB --description "Proposal documents"
  # ... etc
  ```

## Documentation Tasks

- [ ] **8.1** Update README.md if needed
  - Add section on AI assistant integration (optional)
  - Document symlink structure

## Completion Checklist

- [x] Two content files created in `docs/ai/` (AGENTS.md, review-instructions.md)
- [x] All symlinks created and verified (4 root + 2 .github)
- [ ] Labels applied to repository
- [ ] Templates verified on GitHub
- [x] No regressions in existing templates
- [x] Git tracks symlinks correctly

## Dependencies

- Phase 2 depends on Phase 1 (symlinks need targets)
- Phase 3 depends on Phase 1 (symlinks need targets)
- Phases 4-6 are independent

## Parallelization

- Phase 1: Tasks 1.2, 1.3 can be done simultaneously after 1.1
- Phases 4, 5, 6: Can run in parallel
- Phase 2, 3: Must wait for Phase 1 completion
- Phase 7-8: Validation requires all prior phases complete
