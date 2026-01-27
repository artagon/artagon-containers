# Tasks: Publish CI Images

- [x] Update `.github/workflows/build-push.yml` to include all 15 `ci-*` targets in the build matrix.
- [x] Verify the workflow syntax is valid.

## Completion Notes

Completed via PR #28 (merged 2026-01-27). The workflow files were updated with correct Python heredoc syntax (code at column 0) to fix YAML parsing issues.
