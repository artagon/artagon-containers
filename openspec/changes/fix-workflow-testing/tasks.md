# Tasks: Fix Workflow Testing

## Phase 1: Fix SLSA Permissions (Immediate)

- [ ] **1.1** Update `build-push.yml` provenance job permissions to include `actions: read`
- [ ] **1.2** Update `release.yml` provenance job permissions to include `actions: read`
- [ ] **1.3** Verify workflow syntax with `gh workflow view`
- [ ] **1.4** Push fix and verify CI passes

## Phase 2: Workflow Validation Tools

- [ ] **2.1** Add `actionlint` validation to pre-commit or Makefile
- [ ] **2.2** Create `make lint-workflows` target
- [ ] **2.3** Document workflow validation in README or CONTRIBUTING

## Phase 3: Local Testing with `act`

- [ ] **3.1** Create `.actrc` configuration file
- [ ] **3.2** Create `act` secrets template (`.secrets.example`)
- [ ] **3.3** Add `make test-ci` target for running CI workflow locally
- [ ] **3.4** Document act usage and limitations

## Phase 4: Devcontainer Setup

- [ ] **4.1** Create `.devcontainer/devcontainer.json`
- [ ] **4.2** Add `act`, `actionlint`, `docker`, `gh` to devcontainer
- [ ] **4.3** Configure devcontainer for Docker-in-Docker
- [ ] **4.4** Add VS Code extensions for YAML and GitHub Actions
- [ ] **4.5** Test devcontainer build and workflow validation

## Phase 5: CI Integration

- [ ] **5.1** Add workflow lint job to CI pipeline
- [ ] **5.2** Fail CI if workflow syntax errors detected
- [ ] **5.3** Document CI workflow testing in CONTRIBUTING.md
