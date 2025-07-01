#!/bin/bash
# Version Consistency Check Hook
# This script ensures version consistency across different project files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $YELLOW "🔍 Checking version consistency across project files..."

# Array to store found versions
declare -A versions
version_files=()

# Check VERSION file
if [[ -f "VERSION" ]]; then
    version=$(cat VERSION | tr -d '\n\r ')
    versions["VERSION"]="$version"
    version_files+=("VERSION")
    print_status $GREEN "✅ Found VERSION file: $version"
fi

# Check package.json in UI directory
if [[ -f "ui/package.json" ]]; then
    if command -v jq >/dev/null 2>&1; then
        version=$(jq -r '.version' ui/package.json)
        if [[ "$version" != "null" ]]; then
            versions["ui/package.json"]="$version"
            version_files+=("ui/package.json")
            print_status $GREEN "✅ Found ui/package.json version: $version"
        fi
    else
        print_status $YELLOW "⚠️  jq not available, skipping package.json version check"
    fi
fi

# Check Chart.yaml
if [[ -f "helm/kagent/Chart.yaml" ]]; then
    if command -v yq >/dev/null 2>&1; then
        version=$(yq eval '.version' helm/kagent/Chart.yaml)
        if [[ "$version" != "null" ]]; then
            versions["helm/kagent/Chart.yaml"]="$version"
            version_files+=("helm/kagent/Chart.yaml")
            print_status $GREEN "✅ Found Chart.yaml version: $version"
        fi

        # Also check appVersion
        app_version=$(yq eval '.appVersion' helm/kagent/Chart.yaml)
        if [[ "$app_version" != "null" ]]; then
            versions["helm/kagent/Chart.yaml (appVersion)"]="$app_version"
            version_files+=("helm/kagent/Chart.yaml (appVersion)")
            print_status $GREEN "✅ Found Chart.yaml appVersion: $app_version"
        fi
    else
        print_status $YELLOW "⚠️  yq not available, skipping Chart.yaml version check"
    fi
fi

# Check go.mod
if [[ -f "go/go.mod" ]]; then
    # Extract module version if it's tagged
    if git tag >/dev/null 2>&1; then
        latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        if [[ -n "$latest_tag" ]]; then
            versions["git tag"]="$latest_tag"
            version_files+=("git tag")
            print_status $GREEN "✅ Found git tag: $latest_tag"
        fi
    fi
fi

# Check if we found any versions
if [[ ${#versions[@]} -eq 0 ]]; then
    print_status $YELLOW "⚠️  No version files found to check"
    exit 0
fi

# Compare versions for consistency
if [[ ${#versions[@]} -eq 1 ]]; then
    print_status $GREEN "✅ Only one version file found, consistency check passed"
    exit 0
fi

# Get the first version as reference
reference_version=""
reference_file=""
for file in "${version_files[@]}"; do
    reference_version="${versions[$file]}"
    reference_file="$file"
    break
done

print_status $YELLOW "📋 Using $reference_file ($reference_version) as reference"

# Check all other versions against the reference
inconsistent_versions=()
for file in "${version_files[@]}"; do
    version="${versions[$file]}"
    if [[ "$version" != "$reference_version" ]]; then
        inconsistent_versions+=("$file: $version")
    fi
done

# Report results
if [[ ${#inconsistent_versions[@]} -eq 0 ]]; then
    print_status $GREEN "✅ All versions are consistent: $reference_version"
    exit 0
else
    print_status $RED "❌ Version inconsistencies detected:"
    print_status $YELLOW "   Reference: $reference_file = $reference_version"
    for inconsistent in "${inconsistent_versions[@]}"; do
        print_status $RED "   Inconsistent: $inconsistent"
    done

    print_status $YELLOW ""
    print_status $YELLOW "💡 To fix version inconsistencies:"
    print_status $YELLOW "   1. Decide on the correct version"
    print_status $YELLOW "   2. Update all version files to match"
    print_status $YELLOW "   3. Consider using a version bump script for automation"

    exit 1
fi
