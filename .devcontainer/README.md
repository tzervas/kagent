# Kagent Development Container

This devcontainer provides a cross-platform development environment for Windows (WSL), macOS, and Linux with all necessary tools pre-installed.

## Tools Included

- **Python 3.12** - Installed via uv with proper path configuration
- **Go 1.24.3** - Latest Go version for backend development
- **Node.js 20.18.0** - Installed via NVM for frontend development
- **Helm 3.18.3** - Kubernetes package manager
- **Docker CLI** - Container management
- **pre-commit** - Git hooks for code quality enforcement
- **kubectl** - Kubernetes command-line tool
- **kind** - Local Kubernetes clusters
- **k9s** - Kubernetes cluster management UI
- **istioctl** - Istio service mesh management

## Cross-Platform Features

### Mounts

- **Git Configuration**: Automatically mounts and copies `~/.gitconfig` for consistent Git settings
- **SSH Keys**: Securely mounts and configures SSH keys from the host system
- **Docker Socket**: Direct access to host Docker daemon

### Environment Variables

- `TZ=UTC` - Consistent timezone across platforms
- `DOCKER_BUILDKIT=1` - Enhanced Docker build features
- `PYTHONUNBUFFERED=1` - Real-time Python output

### Platform-Specific Support

- **Windows (WSL)**: Full WSL2 integration with proper file permissions
- **macOS**: Native file system performance optimizations
- **Linux**: Direct host integration

## Development Workflow

1. **Container Initialization**: Automatically sets up Git and SSH configurations
2. **Pre-commit Installation**: Installs and configures pre-commit hooks
3. **Tool Verification**: Runs `make print-tools-versions` to verify all tools
4. **Ready State**: Environment ready for immediate development

## VS Code Extensions

The devcontainer includes extensions for:

- Go development (`golang.go`)
- Python development (`ms-python.python`, `ms-python.vscode-pylance`)
- Code quality (`charliermarsh.ruff`, `ms-python.black-formatter`)
- Kubernetes (`ms-kubernetes-tools.vscode-kubernetes-tools`)
- Docker (`ms-azuretools.vscode-docker`)
- Shell scripting (`timonwong.shellcheck`)

## Port Forwarding

- **8082**: Kagent API server
- **3000**: UI development server
- **8080**: Tools server

## Usage

1. Open the project in VS Code
2. Click "Reopen in Container" when prompted
3. Wait for container build and initialization
4. Start developing with all tools pre-configured

## Pre-commit Hooks

Pre-commit hooks are automatically installed and configured to enforce:

- Code formatting (Ruff, Black, ESLint, Prettier)
- Go code quality (gofmt, go vet, golangci-lint)
- Security scanning (detect-secrets)
- Git commit signing verification
- Version consistency checks

Run `pre-commit run --all-files` to check all files against the configured hooks.
