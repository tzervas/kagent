# Local Development Workflow

This document describes the local development workflow for Kagent, including pre-commit hooks and quality assurance measures that mirror our CI/CD pipeline.

## Quick Start

### Initial Setup

1. **Run the setup script** (recommended):

   ```bash
   ./scripts/setup-local-dev.sh
   ```

2. **Manual setup** (if needed):

   ```bash
   # Install UV for Python package management
   curl -LsSf https://astral.sh/uv/install.sh | sh

   # Install pre-commit
   uv tool install pre-commit
   # or: python3 -m pip install --user pre-commit

   # Install pre-commit hooks
   pre-commit install --hook-type pre-commit --hook-type pre-push
   ```

### GPG Signing Setup

Ensure your commits are GPG signed (required):

```bash
# Configure GPG signing globally
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_KEY_ID

# Find your key ID
gpg --list-secret-keys --keyid-format=long
```

## Pre-commit Hooks

Our pre-commit configuration mirrors the CI/CD workflows to catch issues early:

### Automatic Checks (on commit)

- **Code Formatting**: Go fmt, Python ruff format, Prettier for UI
- **Linting**: golangci-lint, ruff check, ESLint
- **Basic Checks**: YAML validation, trailing whitespace, large files
- **Security**: Secret detection with detect-secrets
- **GPG Verification**: Ensures commits are properly signed

### Push Hooks

- **Comprehensive Testing**: Runs full test suite mirroring CI
- **Version Consistency**: Checks version alignment across files

## Test Automation

### Local Test Suite (Mirrors CI Workflows)

Our local test suite mirrors all CI workflows for comprehensive testing:

```bash
# Run complete test suite mirroring CI
./scripts/hooks/run-local-tests.sh
```

**Test Coverage:**

- **Go Unit Tests**: Mirrors `go-unit-tests` CI workflow
- **Python Linting**: Mirrors `lint-python` CI workflow
- **UI Tests**: Mirrors `ui-tests` CI workflow
- **Helm Tests**: Mirrors `helm-unit-tests` CI workflow
- **Security Scans**: Mirrors `image-scan` security checks
- **Build Tests**: Mirrors CI build workflow

### Local E2E Testing (Mirrors CI E2E Workflow)

Run end-to-end tests locally using Kind:

```bash
# Complete E2E test mirroring CI e2e-test workflow
./scripts/test/run-e2e-local.sh
```

**E2E Test Process:**

1. Creates local Kind cluster
2. Builds and loads Docker images
3. Installs Kagent via Helm
4. Runs API connectivity tests
5. Performs health checks
6. Automatic cleanup

**Prerequisites:**

- Docker
- Kind
- kubectl
- Helm
- Make

### Manual Testing Components

### Run Specific Components

#### Go Development

```bash
cd go
go mod tidy
go fmt ./...
go vet ./...
go test -skip 'TestInvokeAPI|TestE2E|TestAutogenClient' -v ./...
```

#### Python Development

```bash
cd python
# Using UV (recommended)
uv sync
uv run ruff check .
uv run ruff format .
uv run pytest tests/

# Or using pip
pip install -e .
ruff check .
pytest tests/
```

#### UI Development

```bash
cd ui
npm ci
npm run lint
npm test
npm audit
```

#### Helm Charts

```bash
helm lint helm/kagent
helm unittest helm/kagent
```

## Development Environment

### Required Tools

- **Git**: Version control with GPG signing
- **Go 1.24+**: Backend development
- **Python 3.12+**: Python components and tooling
- **Node.js 20+**: UI development
- **Helm 3.17+**: Chart development
- **UV**: Python package management (installed automatically)
- **Docker**: Container builds and testing

### Python Environment

We use UV for Python package management, which provides:

- Fast dependency resolution
- Isolated virtual environments
- Tool management
- Lock file generation

```bash
# Install dependencies
cd python && uv sync

# Run commands in the environment
uv run python -m kagent.cli
uv run pytest tests/
uv run ruff check .
```

### Go Environment

```bash
# Download dependencies
cd go && go mod download

# Build CLI
make build-cli-local

# Run tests
go test -v ./...
```

## Quality Standards

### Code Quality

- **Go**: gofmt, go vet, golangci-lint compliance
- **Python**: ruff (PEP 8), type hints, docstrings
- **JavaScript/TypeScript**: ESLint, Prettier
- **YAML**: Valid syntax, consistent formatting

### Testing Requirements

- **Unit Tests**: Required for all new functionality
- **Integration Tests**: For complex workflows
- **E2E Tests**: For critical user paths
- **Idempotent Tests**: Tests should be stable across changes

### Security Requirements

- **GPG Signed Commits**: All commits must be signed
- **Secret Scanning**: No secrets in code
- **Dependency Scanning**: Regular security audits
- **Container Scanning**: Secure base images

## Troubleshooting

### Pre-commit Issues

```bash
# Skip hooks temporarily (not recommended)
git commit --no-verify

# Run hooks manually
pre-commit run --all-files

# Update hook versions
pre-commit autoupdate
```

### GPG Issues

```bash
# Verify GPG setup
./scripts/hooks/verify-gpg-signature.sh

# Check GPG configuration
git config --global --list | grep gpg
gpg --list-secret-keys
```

### Environment Issues

```bash
# Reset Python environment
cd python && uv sync --reinstall

# Clean Go cache
go clean -cache

# Reset Node modules
cd ui && rm -rf node_modules && npm ci
```

### Tool Installation

```bash
# Install UV
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install pre-commit
uv tool install pre-commit

# Install Helm unittest plugin
helm plugin install https://github.com/helm-unittest/helm-unittest
```

## CI/CD Alignment

Our local hooks mirror these CI workflows:

- **go-unit-tests**: Go testing and formatting
- **lint-python**: Python linting with ruff
- **ui-tests**: Node.js testing and linting
- **helm-unit-tests**: Helm chart validation
- **image-scan**: Security scanning (subset)

This ensures that code passing local checks will also pass CI, reducing feedback cycles and improving developer productivity.

## Best Practices

1. **Run hooks before pushing**: Use `./scripts/hooks/run-local-tests.sh`
2. **Keep commits atomic**: One logical change per commit
3. **Write descriptive commit messages**: Follow conventional commits
4. **Test in isolation**: Ensure tests work in clean environments
5. **Update dependencies regularly**: Keep tooling current
6. **Document changes**: Update docs for new workflows

## Getting Help

- **Setup Issues**: Run `./scripts/setup-local-dev.sh` again
- **Hook Failures**: Check the specific tool's documentation
- **Environment Problems**: Use the troubleshooting section above
- **CI Differences**: Ensure local tools match CI versions
