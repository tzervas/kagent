# Enhanced Development Security Features

This document describes the enhanced development security features available in the `feature/enhanced-dev-security` branch, providing optional security improvements for local development workflows.

## Overview

The enhanced development security features are designed to complement (not replace) existing CI workflows by adding security-focused pre-commit hooks and development practices that run locally. These features help developers catch security issues early in the development process while maintaining compatibility with existing workflows.

## What's Included

### Security-Focused Pre-commit Hooks

The enhanced configuration includes security-focused hooks that **do not duplicate** existing CI functionality:

#### 🔒 Secret Detection

- **detect-secrets**: Scans for hardcoded secrets in code
- **gitleaks**: Advanced secret scanning with custom patterns
- Prevents accidental commit of API keys, tokens, and credentials

#### 🛡️ Vulnerability Scanning

- **trivy**: Filesystem vulnerability scanning for dependencies
- Runs on pre-push to catch security issues before they reach remote
- Focuses on HIGH and CRITICAL severity vulnerabilities

#### ✅ Commit Quality

- **conventional-pre-commit**: Enforces conventional commit messages
- **GPG signature verification**: Ensures all commits are properly signed
- **Version consistency checks**: Validates version alignment across files

#### 📝 Documentation Quality

- **markdownlint**: Ensures consistent markdown formatting
- Essential file quality checks (trailing whitespace, merge conflicts, etc.)

### Local Development Scripts

Enhanced hook scripts in `scripts/hooks/`:

- `verify-gpg-signature.sh`: Validates GPG commit signing
- `run-local-tests.sh`: Executes comprehensive local test suite
- `check-version-consistency.sh`: Ensures version alignment

## Optional Adoption

### Why Optional?

These enhanced security features are provided as an **optional enhancement** because:

1. **Non-Breaking**: Existing CI workflows remain unchanged
2. **Performance**: Some security scans can be time-intensive
3. **Flexibility**: Teams can choose their security posture
4. **Environment Specific**: Some tools may not be available in all environments

### Adoption Levels

#### Level 1: Basic Security (Recommended for All)

```bash
# Enable only essential security hooks
git checkout feature/enhanced-dev-security
cp .pre-commit-config.yaml .pre-commit-config-security.yaml
# Edit to include only:
# - detect-secrets
# - conventional-pre-commit
# - basic file quality checks
```

#### Level 2: Comprehensive Security (Recommended for Security-Conscious Teams)

```bash
# Use full enhanced configuration
git checkout feature/enhanced-dev-security
pre-commit install
pre-commit install --hook-type commit-msg
pre-commit install --hook-type pre-push
```

#### Level 3: Custom Configuration

```bash
# Cherry-pick specific hooks based on team needs
# Customize .pre-commit-config.yaml as needed
```

## Prerequisites

### Required Tools

Ensure these security tools are installed for full functionality:

```bash
# Install gitleaks
# macOS
brew install gitleaks

# Linux
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/gitleaks/main/scripts/install.sh | sh -s -- -b /usr/local/bin

# Windows (using Chocolatey)
choco install gitleaks

# Install trivy
# macOS
brew install trivy

# Linux
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Windows (using Chocolatey)
choco install trivy
```

### GPG Configuration

For GPG signature verification:

```bash
# Configure GPG signing (if not already done)
git config --global user.signingkey <your-gpg-key-id>
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

## Installation Guide

### Quick Start

1. **Switch to the enhanced security branch:**

   ```bash
   git checkout feature/enhanced-dev-security
   ```

2. **Install pre-commit hooks:**

   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   pre-commit install --hook-type pre-push
   ```

3. **Test the setup:**

   ```bash
   pre-commit run --all-files
   ```

### Gradual Adoption

1. **Start with basic hooks:**

   ```bash
   # Copy and modify the config to include only basic security hooks
   cp .pre-commit-config.yaml .pre-commit-config-basic.yaml
   # Edit to remove intensive hooks like trivy
   ```

2. **Add hooks progressively:**

   ```bash
   # Add one hook type at a time
   # Test team workflow impact
   # Gradually enable more comprehensive scanning
   ```

## Configuration Options

### Customizing Hook Behavior

#### Adjust Trivy Sensitivity

```yaml
- id: trivy-fs
  entry: trivy fs --exit-code 1 --severity CRITICAL .  # Only CRITICAL
```

#### Skip Hooks for Specific Files

```yaml
- id: detect-secrets
  exclude: |
    (?x)^(
      test-fixtures/.*|
      .*\.lock|
      .*\.min\.js
    )$
```

#### Configure Hook Timing

```yaml
- id: gitleaks
  stages: [pre-commit]  # Run on every commit
# vs
- id: trivy-fs
  stages: [pre-push]    # Run only before push
```

## Team Integration

### Code Review Guidelines

When adopting enhanced security features:

1. **Document decisions**: Note which hooks are enabled and why
2. **Training**: Ensure team understands new security practices
3. **Exceptions**: Create clear process for handling false positives
4. **Monitoring**: Track security improvement metrics

### CI Integration

These hooks complement CI workflows:

- **Local hooks**: Catch issues early in development
- **CI workflows**: Authoritative checks for merge/deployment
- **No duplication**: Enhanced hooks avoid repeating CI checks

## Troubleshooting

### Common Issues

#### Gitleaks False Positives

```bash
# Create .gitleaksignore file for false positives
echo "path/to/false/positive:rule-id" >> .gitleaksignore
```

#### Performance Issues

```bash
# Run only on changed files
pre-commit run --files $(git diff --cached --name-only)

# Skip expensive hooks temporarily
SKIP=trivy-fs git commit -m "temp: skip trivy"
```

#### GPG Issues

```bash
# Verify GPG setup
gpg --list-secret-keys
git config --get user.signingkey

# Test signing
echo "test" | gpg --clear-sign
```

## Migration Path

### From Basic to Enhanced

1. **Assess current setup**: Review existing pre-commit configuration
2. **Identify gaps**: Compare with enhanced security features
3. **Plan adoption**: Choose appropriate adoption level
4. **Test thoroughly**: Run hooks on representative codebase
5. **Train team**: Ensure everyone understands new practices
6. **Monitor impact**: Track development velocity and security posture

### Rollback Strategy

```bash
# Keep backup of original configuration
cp .pre-commit-config.yaml .pre-commit-config-backup.yaml

# Quick rollback if needed
git checkout main -- .pre-commit-config.yaml
pre-commit install
```

## Security Benefits

### Threat Prevention

- **Credential Exposure**: Prevents hardcoded secrets in repositories
- **Vulnerability Introduction**: Catches vulnerable dependencies early
- **Supply Chain**: Validates integrity of development dependencies
- **Audit Trail**: Ensures proper commit signing and attribution

### Compliance Support

- **SOC 2**: Supports access controls and change management
- **ISO 27001**: Demonstrates security in development lifecycle
- **NIST**: Aligns with secure development framework
- **Custom**: Extensible for organization-specific requirements

## Contributing

### Adding New Security Hooks

1. **Research**: Identify security gap or improvement opportunity
2. **Test**: Validate hook effectiveness on real codebase
3. **Document**: Add clear documentation and configuration
4. **Review**: Get security team approval for new hooks

### Reporting Issues

- **Security concerns**: Report privately to security team
- **False positives**: Create issues with reproduction steps
- **Performance**: Include timing data and environment details

## References

- [Pre-commit Hook Documentation](https://pre-commit.com/)
- [Gitleaks Configuration](https://github.com/trufflesecurity/gitleaks)
- [Trivy Security Scanner](https://trivy.dev/)
- [Conventional Commits](https://conventionalcommits.org/)
- [GPG Signing Guide](https://docs.github.com/en/authentication/managing-commit-signature-verification)

---

**Note**: This enhanced security configuration is designed to complement, not replace, existing CI workflows. Always maintain CI as the authoritative security checkpoint while using these tools for early local detection.
