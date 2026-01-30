#!/bin/bash

# OpenIM Server Deployment Script for Linux AMD64 - Single Service
# This script cross-compiles binaries for linux/amd64 on mac arm64, builds Docker image for selected service, pushes to private Harbor, and deploys to Kubernetes

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

# Note: Binaries are built inside the Docker container, so no pre-build needed
GOOS=linux CGO_ENABLE=0 PLATFORMS=linux_amd64 mage build

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

# List of services
services=("openim-api" "openim-crontask" "openim-msggateway" "openim-msgtransfer" "openim-push" "openim-rpc-auth" "openim-rpc-conversation" "openim-rpc-friend" "openim-rpc-group" "openim-rpc-msg" "openim-rpc-third" "openim-rpc-user")

# Display services with numbers
echo "Available services:"
for i in "${!services[@]}"; do
  echo "$((i+1)). ${services[$i]}"
done

# Prompt user to choose a service
read -p "Enter the number of the service to build and deploy: " choice

# Validate choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#services[@]}" ]; then
  echo "Invalid choice. Please enter a number between 1 and ${#services[@]}."
  exit 1
fi

# Get the selected service
selected_service="${services[$((choice-1))]}"
echo "Selected service: $selected_service"

# Build Docker image for the selected service and push to Harbor
services=("$selected_service")

for service in "${services[@]}"; do
  IMAGE_TAG="${HARBOR_URL}/${HARBOR_PROJECT}/${service}:${VERSION}"
  docker buildx build --platform linux/amd64 --load -t $IMAGE_TAG -f build/images/$service/Dockerfile .
  echo "Docker buildx build completed for $service. Checking image architecture:"
  docker inspect $IMAGE_TAG | grep -A 5 '"Architecture"'
  docker push $IMAGE_TAG
  echo "Pushed $IMAGE_TAG"
done

# Update deployment YAML for the selected service to use Harbor image
echo "Updating deployment YAML for $selected_service to use Harbor image..."
DEPLOYMENT_FILE="deployments/deploy/${selected_service}-deployment.yml"
sed -i.bak "s|image: openim/${selected_service}:.*|image: ${IMAGE_TAG}|g" $DEPLOYMENT_FILE

# Deploy to Kubernetes
echo "Starting OpenIM Server Deployment in namespace: $NAMESPACE"

# Apply secrets first
echo "Applying secrets..."
cd deployments/deploy
kubectl apply -f kafka-secret.yml -n $NAMESPACE
kubectl apply -f minio-secret.yml -n $NAMESPACE
kubectl apply -f mongo-secret.yml -n $NAMESPACE
kubectl apply -f redis-secret.yml -n $NAMESPACE

# Apply ConfigMap
echo "Applying ConfigMap..."
kubectl apply -f openim-config.yml -n $NAMESPACE

# Apply the selected service and deployment
echo "Applying selected service: $selected_service"
kubectl apply -f ${selected_service}-service.yml -n $NAMESPACE
kubectl apply -f ${selected_service}-deployment.yml -n $NAMESPACE

cd $ROOT_DIR
echo "OpenIM Server Deployment for $selected_service completed successfully!"
echo "You can check the status with: kubectl get pods -n $NAMESPACE"
echo "Access the API at: http://your-ingress-host/openim-api"
echo "Access the Message Gateway at: http://your-ingress-host/openim-msggateway"