#!/bin/bash
set -euo pipefail

# Local E2E Test Script
# Mirrors the e2e-test workflow from CI for local development
# Provides simplified end-to-end testing using Kind

echo "🧪 Starting local E2E tests (mirrors CI e2e-test workflow)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="kagent-local"
VERSION="v0.0.1-test"
TIMEOUT="300s"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status $YELLOW "🔍 Checking prerequisites..."

MISSING_TOOLS=()

if ! command_exists kind; then
    MISSING_TOOLS+=("kind")
fi

if ! command_exists kubectl; then
    MISSING_TOOLS+=("kubectl")
fi

if ! command_exists helm; then
    MISSING_TOOLS+=("helm")
fi

if ! command_exists docker; then
    MISSING_TOOLS+=("docker")
fi

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    print_status $RED "❌ Missing required tools: ${MISSING_TOOLS[*]}"
    echo "Install missing tools:"
    echo "  kind: https://kind.sigs.k8s.io/docs/user/quick-start/"
    echo "  kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "  helm: https://helm.sh/docs/intro/install/"
    echo "  docker: https://docs.docker.com/get-docker/"
    exit 1
fi

print_status $GREEN "✅ All required tools are available"

# Cleanup function
cleanup() {
    print_status $YELLOW "🧹 Cleaning up..."
    if kind get clusters | grep -q "$CLUSTER_NAME"; then
        print_status $YELLOW "Deleting Kind cluster: $CLUSTER_NAME"
        kind delete cluster --name "$CLUSTER_NAME"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Check if cluster already exists
if kind get clusters | grep -q "$CLUSTER_NAME"; then
    print_status $YELLOW "⚠️  Cluster $CLUSTER_NAME already exists, deleting..."
    kind delete cluster --name "$CLUSTER_NAME"
fi

# Create Kind cluster (mirrors CI setup)
print_status $BLUE "🚀 Creating Kind cluster: $CLUSTER_NAME"
kind create cluster --name "$CLUSTER_NAME" --wait "${TIMEOUT}"

# Verify cluster is ready
print_status $YELLOW "🔍 Verifying cluster readiness..."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

# Setup MetalLB for LoadBalancer services (mirrors CI setup)
print_status $BLUE "🔧 Setting up MetalLB..."
if [[ -f "scripts/kind/setup-metallb.sh" ]]; then
    bash scripts/kind/setup-metallb.sh
else
    print_status $YELLOW "⚠️  MetalLB setup script not found, using NodePort services"
fi

# Build and load images to Kind (simplified version of CI build)
print_status $BLUE "🏗️  Building and loading images..."

export VERSION="$VERSION"
export DOCKER_BUILDKIT=1

# Build core images
for component in controller ui app; do
    print_status $YELLOW "Building $component image..."
    if make "build-$component" &> "/tmp/build-$component.log"; then
        print_status $GREEN "✅ Built $component successfully"

        # Load image to Kind cluster
        print_status $YELLOW "Loading $component image to Kind..."
        kind load docker-image "ghcr.io/kagent-dev/kagent/$component:$VERSION" --name "$CLUSTER_NAME"
    else
        print_status $RED "❌ Failed to build $component"
        echo "Last 10 lines of build log:"
        tail -n 10 "/tmp/build-$component.log"
        exit 1
    fi
done

# Install Kagent using Helm (mirrors CI installation)
print_status $BLUE "📦 Installing Kagent via Helm..."

# Set OpenAI API key if available (for testing)
if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    export OPENAI_API_KEY
    print_status $GREEN "✅ OpenAI API key found, will be used for testing"
else
    print_status $YELLOW "⚠️  No OpenAI API key found, some tests may be skipped"
fi

# Install using make helm-install (mirrors CI)
if make helm-install &> "/tmp/helm-install.log"; then
    print_status $GREEN "✅ Kagent installed successfully"
else
    print_status $RED "❌ Failed to install Kagent"
    echo "Last 20 lines of installation log:"
    tail -n 20 "/tmp/helm-install.log"
    exit 1
fi

# Wait for agents to be ready (mirrors CI wait condition)
print_status $YELLOW "⏳ Waiting for agents to be ready..."
if kubectl wait --for=condition=Accepted agents.kagent.dev -n kagent --all --timeout="${TIMEOUT}"; then
    print_status $GREEN "✅ All agents are ready"
else
    print_status $RED "❌ Timeout waiting for agents to be ready"
    echo "Agent status:"
    kubectl get agents.kagent.dev -n kagent
    exit 1
fi

# Get service information
print_status $BLUE "🔍 Getting service information..."
kubectl get svc -n kagent

# Set up port forwarding for API access (alternative to LoadBalancer)
print_status $YELLOW "🔧 Setting up port forwarding..."
kubectl port-forward -n kagent svc/kagent 8083:8083 &
PORT_FORWARD_PID=$!

# Wait for port forward to be ready
sleep 5

# Test API connectivity (mirrors CI E2E test)
print_status $BLUE "🧪 Running E2E API tests..."

export KAGENT_A2A_URL="http://localhost:8083/api/a2a"

cd go

# Run E2E tests (mirrors CI test execution)
if go test -v -run ^TestInvokeAPI$ github.com/kagent-dev/kagent/go/test/e2e &> "/tmp/e2e-test.log"; then
    print_status $GREEN "✅ E2E tests passed"
else
    print_status $RED "❌ E2E tests failed"
    echo "Last 20 lines of E2E test log:"
    tail -n 20 "/tmp/e2e-test.log"

    # Kill port forward process
    kill $PORT_FORWARD_PID 2>/dev/null || true
    exit 1
fi

# Kill port forward process
kill $PORT_FORWARD_PID 2>/dev/null || true

cd ..

# Additional health checks
print_status $BLUE "🏥 Running health checks..."

# Check pod status
print_status $YELLOW "Checking pod status..."
kubectl get pods -n kagent

# Check agent status
print_status $YELLOW "Checking agent status..."
kubectl get agents.kagent.dev -n kagent

# Check logs for errors
print_status $YELLOW "Checking for errors in logs..."
if kubectl logs -n kagent -l app=kagent --tail=50 | grep -i error; then
    print_status $YELLOW "⚠️  Some errors found in logs (see above)"
else
    print_status $GREEN "✅ No critical errors found in logs"
fi

# Final summary
print_status $GREEN "🎉 Local E2E tests completed successfully!"
print_status $BLUE "📊 Test Summary:"
echo "  - Kind cluster created and configured"
echo "  - Images built and loaded"
echo "  - Kagent installed via Helm"
echo "  - All agents became ready"
echo "  - E2E API tests passed"
echo "  - Health checks completed"

print_status $YELLOW "💡 Note: Cluster will be automatically cleaned up on exit"
