#!/bin/bash

# Script to add nodeSelector to all OpenIM deployments
# This will schedule all pods to node1

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$SCRIPT_DIR"
NODE_NAME="node1"

echo "Adding nodeSelector to all OpenIM deployments..."
echo "Target node: $NODE_NAME"
echo ""

# List of all deployment files
DEPLOYMENT_FILES=(
    "openim-api-deployment.yml"
    "openim-crontask-deployment.yml"
    "openim-msggateway-deployment.yml"
    "openim-msgtransfer-deployment.yml"
    "openim-push-deployment.yml"
    "openim-rpc-auth-deployment.yml"
    "openim-rpc-conversation-deployment.yml"
    "openim-rpc-friend-deployment.yml"
    "openim-rpc-group-deployment.yml"
    "openim-rpc-msg-deployment.yml"
    "openim-rpc-third-deployment.yml"
    "openim-rpc-user-deployment.yml"
)

# Function to add nodeSelector to a deployment file
add_node_selector() {
    local file=$1
    local filepath="$DEPLOYMENT_DIR/$file"

    echo "Processing: $file"

    # Check if file exists
    if [ ! -f "$filepath" ]; then
        echo "  ✗ File not found: $file"
        return
    fi

    # Check if nodeSelector already exists
    if grep -q "nodeSelector:" "$filepath"; then
        echo "  ⚠️  nodeSelector already exists, skipping..."
        return
    fi

    # Add nodeSelector after the spec.template.spec line
    # Using sed to insert the nodeSelector
    sed -i '' '/^    spec:$/a\
      nodeSelector:\
        kubernetes.io/hostname: '"$NODE_NAME"'
' "$filepath"

    echo "  ✓ Added nodeSelector"
}

# Process all deployment files
for file in "${DEPLOYMENT_FILES[@]}"; do
    add_node_selector "$file"
done

echo ""
echo "✓ All deployments updated!"
echo ""
echo "Next steps:"
echo "1. Apply the updated deployments:"
echo "   cd $DEPLOYMENT_DIR"
echo "   kubectl apply -f openim-*-deployment.yml"
echo ""
echo "2. Verify all pods are running on node1:"
echo "   kubectl get pods -n openim -o wide"
echo ""
echo "3. Test the connection:"
echo "   cd $DEPLOYMENT_DIR"
echo "   ./diagnose-grpc-error.sh"
