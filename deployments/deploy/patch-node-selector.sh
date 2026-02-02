#!/bin/bash

# Script to patch all OpenIM deployments with nodeSelector
# This will schedule all pods to node1

NAMESPACE="openim"
NODE_NAME="node1"

echo "Patching all OpenIM deployments with nodeSelector..."
echo "Target node: $NODE_NAME"
echo ""

# List of all deployment names
DEPLOYMENTS=(
    "openim-api"
    "openim-crontask"
    "messagegateway-rpc-server"
    "openim-msgtransfer-server"
    "push-rpc-server"
    "auth-rpc-server"
    "conversation-rpc-server"
    "friend-rpc-server"
    "group-rpc-server"
    "msg-rpc-server"
    "third-rpc-server"
    "user-rpc-server"
)

# Function to patch a deployment
patch_deployment() {
    local deployment=$1

    echo "Patching: $deployment"

    # Patch the deployment with nodeSelector
    kubectl patch deployment -n "$NAMESPACE" "$deployment" -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/hostname":"'"$NODE_NAME"'"}}}}}'

    if [ $? -eq 0 ]; then
        echo "  ✓ Patched successfully"
    else
        echo "  ✗ Failed to patch"
    fi
}

# Process all deployments
for deployment in "${DEPLOYMENTS[@]}"; do
    patch_deployment "$deployment"
done

echo ""
echo "✓ All deployments patched!"
echo ""
echo "Next steps:"
echo "1. Wait for pods to be rescheduled:"
echo "   sleep 30"
echo ""
echo "2. Verify all pods are running on node1:"
echo "   kubectl get pods -n $NAMESPACE -o wide"
echo ""
echo "3. Test the connection:"
echo "   cd /Users/ken/Documents/github.com/a-openim/a-openim-all/open-im-server/deployments/deploy"
echo "   ./diagnose-grpc-error.sh"
