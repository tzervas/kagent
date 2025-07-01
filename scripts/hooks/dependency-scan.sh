#!/bin/bash
set -euo pipefail

# Dependency Vulnerability Scan Script
# Scans project dependencies for known vulnerabilities
# Complements the CI security workflows

echo "🔍 Running dependency vulnerability scan..."

EXIT_CODE=0

# Go dependencies
if [[ -f "go/go.mod" ]]; then
    echo "📦 Scanning Go dependencies..."
    cd go || exit 1
    
    if command -v govulncheck &> /dev/null; then
        echo "  🔍 Running govulncheck..."
        govulncheck ./... || EXIT_CODE=1
    else
        echo "  ⚠️  govulncheck not found. Install with: go install golang.org/x/vuln/cmd/govulncheck@latest"
    fi
    
    if command -v trivy &> /dev/null; then
        echo "  🔍 Running trivy on go.mod..."
        trivy fs --exit-code 1 --severity HIGH,CRITICAL --quiet go.mod || EXIT_CODE=1
    fi
    
    cd ..
fi

# Python dependencies
if [[ -f "python/pyproject.toml" ]] || [[ -f "python/requirements.txt" ]]; then
    echo "📦 Scanning Python dependencies..."
    
    if command -v safety &> /dev/null; then
        echo "  🔍 Running safety check..."
        if [[ -f "python/requirements.txt" ]]; then
            safety check -r python/requirements.txt || EXIT_CODE=1
        fi
    else
        echo "  ⚠️  safety not found. Install with: pip install safety"
    fi
    
    if command -v trivy &> /dev/null; then
        echo "  🔍 Running trivy on Python dependencies..."
        trivy fs --exit-code 1 --severity HIGH,CRITICAL --quiet python/ || EXIT_CODE=1
    fi
fi

# Node.js dependencies
if [[ -f "ui/package.json" ]]; then
    echo "📦 Scanning Node.js dependencies..."
    cd ui || exit 1
    
    if command -v npm &> /dev/null; then
        echo "  🔍 Running npm audit..."
        npm audit --audit-level high || EXIT_CODE=1
    fi
    
    if command -v trivy &> /dev/null; then
        echo "  🔍 Running trivy on package.json..."
        trivy fs --exit-code 1 --severity HIGH,CRITICAL --quiet package.json || EXIT_CODE=1
    fi
    
    cd ..
fi

# Container/Docker dependencies
if command -v trivy &> /dev/null; then
    echo "📦 Scanning container dependencies..."
    echo "  🔍 Running trivy filesystem scan..."
    trivy fs --exit-code 1 --severity HIGH,CRITICAL --quiet . || EXIT_CODE=1
fi

# License compliance check
echo "📄 Checking license compliance..."
if [[ -f "go/go.mod" ]]; then
    cd go || exit 1
    if command -v go-licenses &> /dev/null; then
        echo "  🔍 Checking Go license compliance..."
        go-licenses check ./... || {
            echo "  ⚠️  License compliance issues found"
            EXIT_CODE=1
        }
    else
        echo "  ℹ️  go-licenses not found. Install with: go install github.com/google/go-licenses@latest"
    fi
    cd ..
fi

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ Dependency vulnerability scan completed successfully"
else
    echo "❌ Dependency vulnerability scan found issues"
    exit 1
fi
