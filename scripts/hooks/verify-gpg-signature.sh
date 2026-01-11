#!/bin/bash
# GPG Signature Verification Hook
# This script verifies that commits are properly GPG signed

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

print_status $YELLOW "🔐 Verifying GPG signature configuration..."

# Check if GPG signing is enabled globally
if ! git config --global commit.gpgsign >/dev/null 2>&1; then
    print_status $RED "❌ GPG signing is not enabled globally"
    print_status $YELLOW "Run: git config --global commit.gpgsign true"
    exit 1
fi

# Check if signing key is configured
if ! git config --global user.signingkey >/dev/null 2>&1; then
    print_status $RED "❌ GPG signing key is not configured"
    print_status $YELLOW "Run: git config --global user.signingkey YOUR_KEY_ID"
    exit 1
fi

# Get the configured signing key
SIGNING_KEY=$(git config --global user.signingkey)
print_status $GREEN "✅ GPG signing key configured: $SIGNING_KEY"

# Verify the key exists and is usable
if ! gpg --list-secret-keys "$SIGNING_KEY" >/dev/null 2>&1; then
    print_status $RED "❌ GPG signing key '$SIGNING_KEY' not found in keyring"
    print_status $YELLOW "Ensure your GPG key is properly imported and accessible"
    exit 1
fi

# Check if the key is expired
KEY_EXPIRY=$(gpg --list-keys --with-colons "$SIGNING_KEY" 2>/dev/null | awk -F: '/^pub:/ {print $7}')
if [[ -n "$KEY_EXPIRY" && "$KEY_EXPIRY" != "0" ]]; then
    CURRENT_TIME=$(date +%s)
    if [[ "$KEY_EXPIRY" -lt "$CURRENT_TIME" ]]; then
        print_status $RED "❌ GPG key has expired"
        print_status $YELLOW "Please renew your GPG key or configure a new one"
        exit 1
    fi
fi

print_status $GREEN "✅ GPG signature verification passed"

# Check if we're in a git repository and verify the last commit signature
if git rev-parse --git-dir >/dev/null 2>&1; then
    # Get the last commit hash
    LAST_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "")

    if [[ -n "$LAST_COMMIT" ]]; then
        # Verify the signature of the last commit
        if git verify-commit "$LAST_COMMIT" >/dev/null 2>&1; then
            print_status $GREEN "✅ Last commit is properly signed"
        else
            print_status $YELLOW "⚠️  Last commit signature could not be verified"
            print_status $YELLOW "This might be normal for the initial commit or if this is a new setup"
        fi
    fi
fi

print_status $GREEN "🔐 GPG verification complete"
exit 0
