#!/bin/bash

# OpenIM Server Deployment Script for Linux AMD64
# This script cross-compiles binaries for linux/amd64 on mac arm64, builds Docker images, pushes to private Harbor, and deploys to Kubernetes

set -e

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo "This script should not be run as root due to Docker credential storage issues on macOS."
  echo "Please run this script as your regular user."
  exit 1
fi

ROOT_DIR=$(pwd)
echo $ROOT_DIR

# Source the deployment config
source deploy.confg

NAMESPACE=$NAMESPACE
VERSION=v$(date +%y%m%d%H%M%S)
echo $VERSION > .version

# Cross-compile binaries for linux/amd64
export GOOS=linux
export GOARCH=amd64

# Note: Binaries are built inside the Docker container, so no pre-build needed
# Ask user whether to run mage build
read -p "Do you want to run mage build? (y/n): " run_build
if [[ "$run_build" =~ ^[Yy]$ ]]; then
  echo "Running mage build..."
  GOOS=linux CGO_ENABLE=0 PLATFORMS=linux_amd64 mage build
else
  echo "Skipping mage build..."
fi

# Login to private Harbor
echo "Logging in to Harbor..."
# Set DOCKER_CONFIG to a temporary directory to avoid macOS Keychain issues
export DOCKER_CONFIG=$(mktemp -d)
export DOCKER_CREDS_STORE=""
# Create a config.json with credsStore set to empty string to prevent Keychain usage
echo '{"auths":{},"credsStore":""}' > $DOCKER_CONFIG/config.json
echo "$HARBOR_PASS" | docker login $HARBOR_URL -u $HARBOR_USER --password-stdin

# Unset DOCKER_CONFIG to allow buildx to use default config
unset DOCKER_CONFIG
unset DOCKER_CREDS_STORE

# Check if buildx builder exists, create if not
if ! docker buildx ls | grep -q openim-builder; then
  docker buildx create openim-builder
  docker buildx use openim-builder
else
  docker buildx use openim-builder
fi

# Build Docker images for linux/amd64 and push to Harbor
echo "Building and pushing Docker images for linux/amd64..."

services=("openim-api" "openim-crontask" "openim-msggateway" "openim-msgtransfer" "openim-push" "openim-rpc-auth" "openim-rpc-conversation" "openim-rpc-friend" "openim-rpc-group" "openim-rpc-msg" "openim-rpc-third" "openim-rpc-user")

for service in "${services[@]}"; do
  IMAGE_TAG="${HARBOR_URL}/${HARBOR_PROJECT}/${service}:${VERSION}"
  docker buildx build --platform linux/amd64 --load -t $IMAGE_TAG -f build/images/$service/Dockerfile .
  echo "Docker buildx build completed for $service. Checking image architecture:"
  docker inspect $IMAGE_TAG | grep -A 5 '"Architecture"'
  docker push $IMAGE_TAG
  echo "Pushed $IMAGE_TAG"
done

# Update deployment YAMLs to use Harbor images
echo "Updating deployment YAMLs to use Harbor images..."
for service in "${services[@]}"; do
  DEPLOYMENT_FILE="deployments/deploy/${service}-deployment.yml"
  IMAGE_TAG="${HARBOR_URL}/${HARBOR_PROJECT}/${service}:${VERSION}"
  sed -i.bak "s|image:.*${service}:.*|image: ${IMAGE_TAG}|g" $DEPLOYMENT_FILE
done

# Deploy to Kubernetes
echo "Starting OpenIM Server Deployment in namespace: $NAMESPACE"

# Apply ConfigMap
echo "Applying ConfigMap..."
kubectl apply -f deployments/deploy/openim-config.yml -n $NAMESPACE

# Apply services
echo "Applying services..."
kubectl apply -f deployments/deploy/openim-api-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-msggateway-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-msgtransfer-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-push-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-auth-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-conversation-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-friend-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-group-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-msg-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-third-service.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-user-service.yml -n $NAMESPACE

# Apply Deployments
echo "Applying Deployments..."
kubectl apply -f deployments/deploy/openim-api-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-crontask-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-msggateway-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-msgtransfer-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-push-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-auth-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-conversation-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-friend-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-group-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-msg-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-third-deployment.yml -n $NAMESPACE
kubectl apply -f deployments/deploy/openim-rpc-user-deployment.yml -n $NAMESPACE

# Apply Ingress
echo "Applying Ingress..."
kubectl apply -f deployments/deploy/ingress.yml -n $NAMESPACE

echo "OpenIM Server Deployment completed successfully!"
echo "You can check the status with: kubectl get pods -n $NAMESPACE"
echo "Access the API at: http://your-ingress-host/openim-api"
echo "Access the Message Gateway at: http://your-ingress-host/openim-msggateway"