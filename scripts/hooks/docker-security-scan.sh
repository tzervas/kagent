#!/bin/bash
set -euo pipefail

# Docker Security Scan Script
# Mirrors the security aspects of image-scan.yaml workflow
# Performs static analysis on Dockerfiles before building

echo "🔍 Running Docker security pre-scan..."

# Find all Dockerfiles
DOCKERFILES=$(find . -name "Dockerfile*" -type f)

if [[ -z "$DOCKERFILES" ]]; then
    echo "ℹ️  No Dockerfiles found, skipping Docker security scan"
    exit 0
fi

# Check if hadolint is available
if ! command -v hadolint &> /dev/null; then
    echo "⚠️  hadolint not found. Install with: brew install hadolint"
    echo "ℹ️  Skipping Docker security scan"
    exit 0
fi

# Check if trivy is available for Docker scanning
if ! command -v trivy &> /dev/null; then
    echo "⚠️  trivy not found. Install with: brew install trivy"
    echo "ℹ️  Skipping Docker security scan"
    exit 0
fi

# Scan each Dockerfile
for dockerfile in $DOCKERFILES; do
    echo "🔍 Scanning $dockerfile..."
    
    # Hadolint security checks
    echo "  📋 Running hadolint security checks..."
    hadolint --error DL3008,DL3009,DL3015,DL3025 "$dockerfile"
    
    # Extract base image for security scan
    base_image=$(grep -E '^FROM ' "$dockerfile" | head -1 | awk '{print $2}')
    if [[ -n "$base_image" ]]; then
        echo "  🔍 Scanning base image: $base_image"
        trivy image --exit-code 1 --severity HIGH,CRITICAL --quiet "$base_image" || {
            echo "❌ Security vulnerabilities found in base image: $base_image"
            echo "💡 Consider using a more secure base image or updating to latest version"
            exit 1
        }
    fi
done

echo "✅ Docker security pre-scan completed successfully"
