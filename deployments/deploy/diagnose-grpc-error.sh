#!/bin/bash

# OpenIM gRPC Connection Diagnostic Script
# This script helps diagnose the "grpc service msg-rpc-service down" error

set -e

NAMESPACE="openim"
SERVICE_NAME="msg-rpc-service"
EXPECTED_PORT=10280

echo "=========================================="
echo "OpenIM gRPC Connection Diagnostic Tool"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print section header
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

print_success "kubectl is available"

# Step 1: Check if namespace exists
print_header "Step 1: Checking Namespace"
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_success "Namespace '$NAMESPACE' exists"
else
    print_error "Namespace '$NAMESPACE' does not exist"
    exit 1
fi

# Step 2: Check msg-rpc-server pod status
print_header "Step 2: Checking msg-rpc-server Pod Status"
POD_STATUS=$(kubectl get pods -n "$NAMESPACE" -l app=msg-rpc-server -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "")

if [ -z "$POD_STATUS" ]; then
    print_error "No pods found with label app=msg-rpc-server"
    echo ""
    echo "All pods in namespace:"
    kubectl get pods -n "$NAMESPACE"
    exit 1
fi

if [ "$POD_STATUS" = "Running" ]; then
    print_success "msg-rpc-server pod is running"
    kubectl get pods -n "$NAMESPACE" -l app=msg-rpc-server
else
    print_error "msg-rpc-server pod is not running (status: $POD_STATUS)"
    echo ""
    echo "Pod details:"
    kubectl get pods -n "$NAMESPACE" -l app=msg-rpc-server
    echo ""
    echo "Pod events:"
    kubectl describe pod -n "$NAMESPACE" -l app=msg-rpc-server | tail -20
fi

# Step 3: Check service configuration
print_header "Step 3: Checking Service Configuration"
if kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME" &> /dev/null; then
    print_success "Service '$SERVICE_NAME' exists"
    kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME"
    echo ""
    echo "Service details:"
    kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME" -o yaml | grep -A 10 "ports:"
else
    print_error "Service '$SERVICE_NAME' does not exist"
    echo ""
    echo "All services in namespace:"
    kubectl get svc -n "$NAMESPACE"
    exit 1
fi

# Step 4: Check service endpoints
print_header "Step 4: Checking Service Endpoints"
ENDPOINTS=$(kubectl get endpoints -n "$NAMESPACE" "$SERVICE_NAME" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")

if [ -z "$ENDPOINTS" ]; then
    print_error "No endpoints found for service '$SERVICE_NAME'"
    echo ""
    echo "Endpoints details:"
    kubectl get endpoints -n "$NAMESPACE" "$SERVICE_NAME"
    echo ""
    print_warning "This means the service selector doesn't match any pod labels"
    echo ""
    echo "Pod labels:"
    kubectl get pods -n "$NAMESPACE" -l app=msg-rpc-server -o jsonpath='{.items[*].metadata.labels}'
    echo ""
    echo "Service selector:"
    kubectl get svc -n "$NAMESPACE" "$SERVICE_NAME" -o jsonpath='{.spec.selector}'
else
    print_success "Endpoints found: $ENDPOINTS"
    kubectl get endpoints -n "$NAMESPACE" "$SERVICE_NAME"
fi

# Step 5: Check pod logs for errors
print_header "Step 5: Checking Pod Logs"
echo "Recent logs from msg-rpc-server:"
kubectl logs -n "$NAMESPACE" -l app=msg-rpc-server --tail=50 2>&1 || print_error "Failed to retrieve logs"

# Step 6: Test connectivity from within cluster
print_header "Step 6: Testing Internal Connectivity"
echo "Creating temporary pod to test connectivity..."

# Create a temporary pod for testing
cat <<EOF | kubectl apply -f - 2>/dev/null || true
apiVersion: v1
kind: Pod
metadata:
  name: grpc-test-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: test
    image: curlimages/curl:latest
    command: ["sh", "-c", "sleep 3600"]
  restartPolicy: Never
EOF

# Wait for pod to be ready
echo "Waiting for test pod to be ready..."
kubectl wait --for=condition=ready pod/grpc-test-pod -n "$NAMESPACE" --timeout=30s 2>/dev/null || print_warning "Test pod not ready, skipping connectivity test"

if kubectl get pod grpc-test-pod -n "$NAMESPACE" &> /dev/null; then
    echo ""
    echo "Testing TCP connection to $SERVICE_NAME:$EXPECTED_PORT..."
    if kubectl exec -n "$NAMESPACE" grpc-test-pod -- nc -zv "$SERVICE_NAME" "$EXPECTED_PORT" 2>&1 | grep -q "succeeded"; then
        print_success "TCP connection to $SERVICE_NAME:$EXPECTED_PORT successful"
    else
        print_error "TCP connection to $SERVICE_NAME:$EXPECTED_PORT failed"
        kubectl exec -n "$NAMESPACE" grpc-test-pod -- nc -zv "$SERVICE_NAME" "$EXPECTED_PORT" 2>&1 || true
    fi

    echo ""
    echo "Testing HTTP connection (expecting HTTP/1.1 response since gRPC uses HTTP/2)..."
    kubectl exec -n "$NAMESPACE" grpc-test-pod -- curl -v "http://$SERVICE_NAME:$EXPECTED_PORT" 2>&1 | head -20 || print_error "HTTP connection failed"

    # Cleanup test pod
    kubectl delete pod grpc-test-pod -n "$NAMESPACE" --force --grace-period=0 2>/dev/null || true
fi

# Step 7: Check ConfigMap
print_header "Step 7: Checking ConfigMap Configuration"
if kubectl get configmap -n "$NAMESPACE" openim-config &> /dev/null; then
    print_success "ConfigMap 'openim-config' exists"
    echo ""
    echo "Discovery configuration:"
    kubectl get configmap -n "$NAMESPACE" openim-config -o jsonpath='{.data.discovery\.yml}'
    echo ""
    echo "RPC service names:"
    kubectl get configmap -n "$NAMESPACE" openim-config -o jsonpath='{.data.discovery\.yml}' | grep -A 10 "rpcService:"
else
    print_error "ConfigMap 'openim-config' does not exist"
fi

# Step 8: Check network policies
print_header "Step 8: Checking Network Policies"
NETWORK_POLICIES=$(kubectl get networkpolicies -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

if [ -z "$NETWORK_POLICIES" ]; then
    print_success "No network policies found (traffic should be unrestricted)"
else
    print_warning "Network policies found - they may be blocking traffic"
    kubectl get networkpolicies -n "$NAMESPACE"
fi

# Step 9: Check ingress configuration
print_header "Step 9: Checking Ingress Configuration"
INGRESS_COUNT=$(kubectl get ingress -n "$NAMESPACE" 2>/dev/null | wc -l)

if [ "$INGRESS_COUNT" -gt 0 ]; then
    print_warning "Ingress resources found - RPC services should NOT be exposed via ingress"
    kubectl get ingress -n "$NAMESPACE"
    echo ""
    echo "Note: RPC services should use internal service discovery, not ingress"
else
    print_success "No ingress resources found (correct for RPC services)"
fi

# Step 10: Summary and Recommendations
print_header "Step 10: Summary and Recommendations"

echo ""
echo "Common Issues and Solutions:"
echo ""
echo "1. If pod is not running:"
echo "   - Check pod logs: kubectl logs -n $NAMESPACE -l app=msg-rpc-server"
echo "   - Check pod events: kubectl describe pod -n $NAMESPACE -l app=msg-rpc-server"
echo "   - Verify image exists and is accessible"
echo ""
echo "2. If service has no endpoints:"
echo "   - Verify pod labels match service selector"
echo "   - Check: kubectl get pods -n $NAMESPACE -l app=msg-rpc-server --show-labels"
echo "   - Check: kubectl get svc -n $NAMESPACE $SERVICE_NAME -o yaml | grep selector"
echo ""
echo "3. If connectivity test fails:"
echo "   - Check network policies: kubectl get networkpolicies -n $NAMESPACE"
echo "   - Verify pod is in the same namespace"
echo "   - Check firewall rules"
echo ""
echo "4. If logs show gRPC errors:"
echo "   - Verify service discovery is using 'kubernetes' mode"
echo "   - Check ConfigMap discovery.yml configuration"
echo "   - Ensure all RPC services are running"
echo ""
echo "5. HTTP/2 vs HTTP/1.1 error:"
echo "   - This error typically means the client is connecting through an HTTP/1.1 endpoint"
echo "   - Ensure RPC services use internal service discovery (not ingress)"
echo "   - Verify client is using correct service name: $SERVICE_NAME:$EXPECTED_PORT"
echo ""

print_header "Diagnostic Complete"
echo ""
echo "For more information, see: open-im-server/deployments/deploy/TROUBLESHOOTING_GRPC_ERROR.md"
