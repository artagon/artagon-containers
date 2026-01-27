# Tasks: Fix Workflow Testing

## Phase 1: Fix SLSA Permissions (Immediate)

- [x] **1.1** Update `build-push.yml` provenance job permissions to include `actions: read`
- [x] **1.2** Update `release.yml` provenance job permissions to include `actions: read`
- [x] **1.3** Verify workflow syntax with `gh workflow view`
- [x] **1.4** Push fix and verify CI passes

## Phase 2: Workflow Validation Tools

- [x] **2.1** Add `actionlint` validation to Makefile
- [x] **2.2** Create `make lint-workflows` target
- [ ] **2.3** Document workflow validation in README or CONTRIBUTING

## Phase 3: Local Testing with `act`

- [x] **3.1** Create `.actrc` configuration file
- [x] **3.2** Create `act` secrets template (`.secrets.example`)
- [x] **3.3** Add `make test-ci` target for running CI workflow locally
- [ ] **3.4** Document act usage and limitations

## Phase 4: Nix Development Environment

- [x] **4.1** Create `flake.nix` with dev shell
- [x] **4.2** Include `act`, `actionlint`, `docker`, `gh`, security tools
- [ ] **4.3** Test `nix develop` and workflow validation

## Phase 5: CI Integration

- [ ] **5.1** Add workflow lint job to CI pipeline
- [ ] **5.2** Fail CI if workflow syntax errors detected
- [ ] **5.3** Document CI workflow testing in CONTRIBUTING.md
