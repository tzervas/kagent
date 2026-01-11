#!/bin/bash
# Local Test Runner Hook
# This script runs local tests that mirror the CI workflows

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

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name=$1
    shift
    local test_command=("$@")

    print_status $YELLOW "🧪 Running: $test_name"

    if "${test_command[@]}"; then
        print_status $GREEN "✅ $test_name passed"
        ((TESTS_PASSED++))
        return 0
    else
        print_status $RED "❌ $test_name failed"
        ((TESTS_FAILED++))
        return 1
    fi
}

print_header "Local Test Suite"

# Check for required tools
print_status $YELLOW "🔍 Checking required tools..."

MISSING_TOOLS=()

if ! command_exists go; then
    MISSING_TOOLS+=("go")
fi

if ! command_exists helm; then
    MISSING_TOOLS+=("helm")
fi

if ! command_exists node; then
    MISSING_TOOLS+=("node")
fi

if ! command_exists npm; then
    MISSING_TOOLS+=("npm")
fi

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    print_status $RED "❌ Missing required tools: ${MISSING_TOOLS[*]}"
    print_status $YELLOW "Please install missing tools before running tests"
    exit 1
fi

print_status $GREEN "✅ All required tools are available"

# Go Tests - mirrors go-unit-tests CI workflow
if [[ -d "go" ]]; then
    print_header "Go Unit Tests (mirrors CI go-unit-tests)"

    cd go

    # Check Go version (CI uses Go 1.24)
    GO_VERSION=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | sed 's/go//')
    print_status $YELLOW "🔍 Using Go version: $GO_VERSION"

    # Run go mod tidy
    run_test "Go mod tidy" go mod tidy

    # Run go fmt check
    run_test "Go format check" sh -c 'test -z "$(gofmt -l .)"'

    # Run go vet
    run_test "Go vet" go vet ./...

    # Run unit tests exactly as CI does (excluding e2e and integration tests)
    run_test "Go unit tests (CI mirror)" go test -skip 'TestInvokeAPI|TestE2E|TestAutogenClient' -v ./...

    cd ..
else
    print_status $YELLOW "⚠️  No Go directory found, skipping Go tests"
fi

# Python Tests - mirrors lint-python CI workflow
if [[ -d "python" ]]; then
    print_header "Python Tests (mirrors CI lint-python)"

    cd python

    # Check if UV is available (project uses UV for Python package management)
    if command_exists uv; then
        print_status $GREEN "✅ UV detected, using for Python dependency management"

        # Install dependencies using UV
        run_test "UV sync dependencies" uv sync

        # Run ruff linting (matches CI lint-python workflow)
        run_test "Ruff linting (CI mirror)" uv run ruff check .

        # Run ruff formatting
        run_test "Ruff formatting" uv run ruff format --check .

        # Run Python tests if available
        if [[ -d "tests" ]]; then
            run_test "Python unit tests" uv run pytest tests/
        fi
    else
        print_status $YELLOW "⚠️  UV not available, trying pip"

        # Fallback to pip if UV not available
        if [[ -f "pyproject.toml" ]]; then
            run_test "Install Python dependencies" pip install -e .

            # Run ruff if available
            if command_exists ruff; then
                run_test "Ruff linting" ruff check .
                run_test "Ruff formatting" ruff format --check .
            fi

            # Run pytest if available
            if command_exists pytest && [[ -d "tests" ]]; then
                run_test "Python unit tests" pytest tests/
            fi
        fi
    fi

    cd ..
else
    print_status $YELLOW "⚠️  No Python directory found, skipping Python tests"
fi

# Helm Tests
if [[ -d "helm" ]]; then
    print_header "Helm Unit Tests"

    # Check if helm unittest plugin is installed
    if ! helm plugin list | grep -q unittest; then
        print_status $YELLOW "Installing helm unittest plugin..."
        helm plugin install https://github.com/helm-unittest/helm-unittest
    fi

    # Run helm lint
    run_test "Helm lint" helm lint helm/kagent

    # Run helm unittest
    run_test "Helm unit tests" helm unittest helm/kagent

else
    print_status $YELLOW "⚠️  No Helm directory found, skipping Helm tests"
fi

# UI Tests
if [[ -d "ui" ]]; then
    print_header "UI Tests"

    cd ui

    # Check if node_modules exists
    if [[ ! -d "node_modules" ]]; then
        print_status $YELLOW "Installing npm dependencies..."
        npm ci
    fi

    # Run npm audit
    run_test "NPM security audit" npm audit --audit-level=moderate

    # Run linting if available
    if npm run lint --silent 2>/dev/null; then
        run_test "ESLint" npm run lint
    else
        print_status $YELLOW "⚠️  No lint script found in package.json"
    fi

    # Run tests
    run_test "UI unit tests" npm test

    cd ..
else
    print_status $YELLOW "⚠️  No UI directory found, skipping UI tests"
fi

# Security Checks
print_header "Security Checks"

# Check for secrets
if command_exists detect-secrets; then
    run_test "Secret detection" detect-secrets scan --all-files
else
    print_status $YELLOW "⚠️  detect-secrets not available, skipping secret scan"
fi

# Summary
print_header "Test Summary"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

print_status $GREEN "✅ Passed: $TESTS_PASSED"
if [[ $TESTS_FAILED -gt 0 ]]; then
    print_status $RED "❌ Failed: $TESTS_FAILED"
else
    print_status $GREEN "❌ Failed: $TESTS_FAILED"
fi
print_status $BLUE "📊 Total: $TOTAL_TESTS"

if [[ $TESTS_FAILED -gt 0 ]]; then
    print_status $RED "🚫 Some tests failed. Please fix the issues before pushing."
    exit 1
else
    print_status $GREEN "🎉 All tests passed! Ready to push."
    exit 0
fi
