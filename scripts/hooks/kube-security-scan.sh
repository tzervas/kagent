#!/bin/bash
set -euo pipefail

# Kubernetes Security Scan Script
# Performs security analysis on Kubernetes manifests and Helm charts
# Complements the CI security workflows

echo "🔍 Running Kubernetes security scan..."

# Find Kubernetes manifests and Helm charts
K8S_FILES=$(find . -name "*.yaml" -o -name "*.yml" | grep -E "(helm/|k8s/|kubernetes/)" || true)

if [[ -z "$K8S_FILES" ]]; then
    echo "ℹ️  No Kubernetes manifests found, skipping K8s security scan"
    exit 0
fi

# Check if tools are available
TOOLS_MISSING=0

if ! command -v trivy &> /dev/null; then
    echo "⚠️  trivy not found. Install with: brew install trivy"
    TOOLS_MISSING=1
fi

if ! command -v kube-score &> /dev/null; then
    echo "⚠️  kube-score not found. Install with: brew install kube-score"
    TOOLS_MISSING=1
fi

if [[ $TOOLS_MISSING -eq 1 ]]; then
    echo "ℹ️  Some security tools missing, performing basic checks only"
fi

# Basic security checks for all files
echo "📋 Performing basic Kubernetes security checks..."

for file in $K8S_FILES; do
    echo "  🔍 Checking $file..."
    
    # Check for common security anti-patterns
    if grep -q "privileged.*true" "$file"; then
        echo "    ❌ Found privileged container in $file"
        exit 1
    fi
    
    if grep -q "runAsRoot.*true" "$file"; then
        echo "    ❌ Found container running as root in $file"
        exit 1
    fi
    
    if grep -q "allowPrivilegeEscalation.*true" "$file"; then
        echo "    ❌ Found privilege escalation allowed in $file"
        exit 1
    fi
    
    if grep -q "hostNetwork.*true" "$file"; then
        echo "    ⚠️  Found hostNetwork enabled in $file"
    fi
    
    if grep -q "hostPID.*true" "$file"; then
        echo "    ❌ Found hostPID enabled in $file"
        exit 1
    fi
    
    # Check for secrets in plain text
    if grep -qE "(password|secret|key|token).*:" "$file" && ! grep -q "secretKeyRef\|configMapKeyRef" "$file"; then
        echo "    ⚠️  Potential hardcoded secret in $file"
    fi
done

# Advanced security scanning with trivy
if command -v trivy &> /dev/null; then
    echo "🔍 Running Trivy config scan..."
    trivy config --exit-code 1 --severity HIGH,CRITICAL --quiet .
fi

# Kubernetes best practices with kube-score
if command -v kube-score &> /dev/null; then
    echo "📊 Running kube-score analysis..."
    for file in $K8S_FILES; do
        if kubectl --dry-run=client apply -f "$file" &> /dev/null; then
            kube-score score "$file" --exit-one-on-warning || {
                echo "⚠️  kube-score found issues in $file"
            }
        fi
    done
fi

echo "✅ Kubernetes security scan completed"
