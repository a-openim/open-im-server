#!/bin/bash

# Script to rebuild and redeploy services after fixing kuberesolver panic
# This script rebuilds the tools package and all affected services

set -e

echo "=========================================="
echo "Rebuilding tools package with kuberesolver fix"
echo "=========================================="

cd tools
echo "Building tools package..."
go build ./...
echo "✓ Tools package built successfully"
cd ..

echo ""
echo "=========================================="
echo "Rebuilding open-im-server with updated tools"
echo "=========================================="

cd open-im-server
echo "Building open-im-server..."
go build ./...
echo "✓ open-im-server built successfully"
cd ..

echo ""
echo "=========================================="
echo "Rebuilding Docker images"
echo "=========================================="

# Rebuild all RPC service images
SERVICES=(
    "openim-rpc-msg"
    "openim-rpc-user"
    "openim-rpc-auth"
    "openim-rpc-conversation"
    "openim-rpc-friend"
    "openim-rpc-group"
    "openim-rpc-third"
    "openim-push"
    "openim-msggateway"
    "openim-api"
)

for service in "${SERVICES[@]}"; do
    echo ""
    echo "Building $service image..."
    cd open-im-server
    docker build -f build/images/$service/Dockerfile -t 10.88.88.13:81/app/$service:v$(date +%y%m%d%H%M%S) .
    cd ..
    echo "✓ $service image built"
done

echo ""
echo "=========================================="
echo "Build complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Update the image tags in your deployment YAML files"
echo "2. Run: kubectl apply -f <deployment-file>.yml"
echo "3. Check logs: kubectl logs -f deployment/msg-rpc-server -n openim"
echo ""
echo "The kuberesolver panic should now be resolved!"
