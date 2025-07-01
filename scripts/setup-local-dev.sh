#!/bin/bash
# Local Development Environment Setup
# This script sets up the local development environment with pre-commit hooks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    local message=$1
    echo
    print_status $BLUE "================== $message =================="
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_header "Kagent Local Development Environment Setup"

# Check for required tools
print_status $YELLOW "🔍 Checking for required development tools..."

MISSING_TOOLS=()

# Check for Git
if ! command_exists git; then
    MISSING_TOOLS+=("git")
fi

# Check for Python
if ! command_exists python3; then
    MISSING_TOOLS+=("python3")
fi

# Check for Go
if ! command_exists go; then
    print_status $YELLOW "⚠️  Go not found. Go is required for this project."
    MISSING_TOOLS+=("go")
fi

# Check for Node.js
if ! command_exists node; then
    print_status $YELLOW "⚠️  Node.js not found. Node.js is required for UI development."
    MISSING_TOOLS+=("node")
fi

# Check for Helm
if ! command_exists helm; then
    print_status $YELLOW "⚠️  Helm not found. Helm is required for chart development."
    MISSING_TOOLS+=("helm")
fi

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    print_status $RED "❌ Missing required tools: ${MISSING_TOOLS[*]}"
    print_status $YELLOW "Please install the missing tools and run this script again."
    exit 1
fi

print_status $GREEN "✅ All basic tools are available"

# Install UV if not present
if ! command_exists uv; then
    print_status $YELLOW "📦 Installing UV for Python package management..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"

    if command_exists uv; then
        print_status $GREEN "✅ UV installed successfully"
    else
        print_status $RED "❌ Failed to install UV. Please install manually."
        exit 1
    fi
else
    print_status $GREEN "✅ UV is already installed"
fi

# Install pre-commit
print_status $YELLOW "🔧 Setting up pre-commit..."

if ! command_exists pre-commit; then
    # Try to install with UV first, fallback to pip
    if command_exists uv; then
        uv tool install pre-commit
    else
        python3 -m pip install --user pre-commit
    fi

    if command_exists pre-commit; then
        print_status $GREEN "✅ pre-commit installed successfully"
    else
        print_status $RED "❌ Failed to install pre-commit"
        exit 1
    fi
else
    print_status $GREEN "✅ pre-commit is already installed"
fi

# Install pre-commit hooks
print_status $YELLOW "🪝 Installing pre-commit hooks..."
pre-commit install --hook-type pre-commit --hook-type pre-push

print_status $GREEN "✅ Pre-commit hooks installed"

# Setup Python environment
if [[ -d "python" ]]; then
    print_header "Python Environment Setup"

    cd python

    if [[ -f "pyproject.toml" ]]; then
        print_status $YELLOW "📦 Setting up Python virtual environment with UV..."
        uv sync
        print_status $GREEN "✅ Python environment ready"
    fi

    cd ..
fi

# Setup Go environment
if [[ -d "go" ]]; then
    print_header "Go Environment Setup"

    cd go

    print_status $YELLOW "📦 Downloading Go dependencies..."
    go mod download
    print_status $GREEN "✅ Go dependencies ready"

    cd ..
fi

# Setup UI environment
if [[ -d "ui" ]]; then
    print_header "UI Environment Setup"

    cd ui

    if [[ -f "package.json" ]]; then
        print_status $YELLOW "📦 Installing Node.js dependencies..."
        npm ci
        print_status $GREEN "✅ UI dependencies ready"
    fi

    cd ..
fi

# Setup Helm
if [[ -d "helm" ]]; then
    print_header "Helm Environment Setup"

    # Install helm unittest plugin if not present
    if ! helm plugin list | grep -q unittest; then
        print_status $YELLOW "📦 Installing Helm unittest plugin..."
        helm plugin install https://github.com/helm-unittest/helm-unittest
        print_status $GREEN "✅ Helm unittest plugin installed"
    else
        print_status $GREEN "✅ Helm unittest plugin already installed"
    fi
fi

# Verify GPG configuration
print_header "GPG Configuration Check"

if git config --global commit.gpgsign >/dev/null 2>&1; then
    SIGNING_KEY=$(git config --global user.signingkey)
    print_status $GREEN "✅ GPG signing is enabled with key: $SIGNING_KEY"
else
    print_status $YELLOW "⚠️  GPG signing is not configured globally"
    print_status $YELLOW "To enable GPG signing, run:"
    print_status $YELLOW "  git config --global commit.gpgsign true"
    print_status $YELLOW "  git config --global user.signingkey YOUR_KEY_ID"
fi

# Test pre-commit setup
print_header "Testing Pre-commit Setup"

print_status $YELLOW "🧪 Running pre-commit on all files to test setup..."
if pre-commit run --all-files; then
    print_status $GREEN "✅ Pre-commit setup test passed"
else
    print_status $YELLOW "⚠️  Some pre-commit checks failed, but that's normal for the first run"
    print_status $YELLOW "The hooks will work correctly on future commits"
fi

print_header "Setup Complete!"

print_status $GREEN "🎉 Local development environment is ready!"
print_status $BLUE "📋 What's been set up:"
print_status $BLUE "  • Pre-commit hooks for code quality"
print_status $BLUE "  • Python environment with UV"
print_status $BLUE "  • Go dependencies"
print_status $BLUE "  • Node.js/UI dependencies"
print_status $BLUE "  • Helm with unittest plugin"
print_status $BLUE ""
print_status $BLUE "💡 Usage tips:"
print_status $BLUE "  • Hooks run automatically on commit and push"
print_status $BLUE "  • Run './scripts/hooks/run-local-tests.sh' to test manually"
print_status $BLUE "  • Run 'pre-commit run --all-files' to check all files"
print_status $BLUE "  • Use 'uv run' for Python commands in the python directory"

exit 0
