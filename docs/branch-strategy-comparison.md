# Branch Strategy Comparison: Local Development Workflow vs. Enhanced Development Security

## Introduction

This document outlines the rationale for creating and separating two feature branches within our project:

1. **feature/local-dev-workflow**: Retains only mirror hooks to align local development closely with Continuous Integration (CI) workflows.
2. **feature/enhanced-dev-security**: Contains all available hooks, including additional security and quality checks not covered in the CI workflows.

## feature/local-dev-workflow

### Purpose

- **Consistency with CI**: This branch mirrors the CI hooks, ensuring that developers experience the same checks locally as in the CI pipelines.
- **Efficiency**: By limiting hooks to those directly corresponding to CI, local development stays efficient, minimizing time spent on checks that aren't validated later in CI.

### Hooks Included

- **Go Development**: All hooks corresponding to the `go-unit-tests` CI workflow.
- **Python Development**: Hooks equivalent to the `lint-python` CI workflow (ruff).
- **UI/Frontend Development**: JavaScript/TypeScript linting and formatting consistent with `ui-tests`.
- **Docker and Kubernetes**: Basic linting for Dockerfile and Helm charts.

## feature/enhanced-dev-security

### Purpose

- **Comprehensive Security**: Ensure complete coverage of security, quality, and development standards not included in CI.
- **Pre-Push Validation**: Runs extensive checks before code is pushed, preventing issues from reaching remote branches.

### Hooks Included

- **All Hooks**: Incorporates all available hooks, including security scanning (e.g., detect-secrets, gitleaks), consistency checks, and more.

### Additional Security Features

- **Secret Scanning**: Detect secrets in code and block insecure code from being pushed.
- **Version Consistency**: Ensure consistency across version files.
- **GPG Verification**: Enforce GPG signature verification on commit messages.

## Conclusion

Organizing hooks into these two branches facilitates our focus on **smooth everyday development** while allowing a dedicated branch with increased focus on **security and code quality**, ensuring our commitment to best practices.
