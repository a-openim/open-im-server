#!/bin/bash

# OpenIM Server Deployment Script for Linux AMD64
# This script cross-compiles binaries for linux/amd64 on mac arm64, builds Docker images, pushes to private Harbor, and deploys to Kubernetes

set -e

# Source the deployment config
source deploy.confg

NAMESPACE=$NAMESPACE
VERSION=v3.8.3

# Cross-compile binaries for linux/amd64
export GOOS=linux
export GOARCH=amd64

echo "Building binaries for linux/amd64..."
# Use mage build with explicit platform specification
mage build linux_amd64

# Login to private Harbor
echo "Logging in to Harbor..."
echo "$HARBOR_PASS" | docker login $HARBOR_URL -u $HARBOR_USER --password-stdin

# Build Docker images for linux/amd64 and push to Harbor
echo "Building and pushing Docker images for linux/amd64..."

docker buildx create --use --name openim-builder || true

services=("openim-api" "openim-crontask" "openim-msggateway" "openim-msgtransfer" "openim-push" "openim-rpc-auth" "openim-rpc-conversation" "openim-rpc-friend" "openim-rpc-group" "openim-rpc-msg" "openim-rpc-third" "openim-rpc-user")

for service in "${services[@]}"; do
  IMAGE_TAG="${HARBOR_URL}/${HARBOR_PROJECT}/${service}:${VERSION}"
  docker buildx build --platform linux/amd64 -t $IMAGE_TAG build/images/$service/ --push
done

# Update deployment YAMLs to use Harbor images
echo "Updating deployment YAMLs to use Harbor images..."
for service in "${services[@]}"; do
  DEPLOYMENT_FILE="${service}-deployment.yml"
  IMAGE_TAG="${HARBOR_URL}/${HARBOR_PROJECT}/${service}:${VERSION}"
  sed -i.bak "s|image: openim/${service}:.*|image: ${IMAGE_TAG}|g" $DEPLOYMENT_FILE
done

# Deploy to Kubernetes
echo "Starting OpenIM Server Deployment in namespace: $NAMESPACE"

# Apply secrets first
echo "Applying secrets..."
kubectl apply -f kafka-secret.yml -n $NAMESPACE
kubectl apply -f minio-secret.yml -n $NAMESPACE
kubectl apply -f mongo-secret.yml -n $NAMESPACE
kubectl apply -f redis-secret.yml -n $NAMESPACE

# Apply ConfigMap
echo "Applying ConfigMap..."
kubectl apply -f openim-config.yml -n $NAMESPACE

# Apply services
echo "Applying services..."
kubectl apply -f kafka-service.yml -n $NAMESPACE
kubectl apply -f minio-service.yml -n $NAMESPACE
kubectl apply -f mongo-service.yml -n $NAMESPACE
kubectl apply -f redis-service.yml -n $NAMESPACE
kubectl apply -f openim-api-service.yml -n $NAMESPACE
kubectl apply -f openim-msggateway-service.yml -n $NAMESPACE
kubectl apply -f openim-msgtransfer-service.yml -n $NAMESPACE
kubectl apply -f openim-push-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-auth-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-conversation-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-friend-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-group-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-msg-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-third-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-user-service.yml -n $NAMESPACE

# Apply StatefulSets
echo "Applying StatefulSets..."
kubectl apply -f kafka-statefulset.yml -n $NAMESPACE
kubectl apply -f minio-statefulset.yml -n $NAMESPACE
kubectl apply -f mongo-statefulset.yml -n $NAMESPACE
kubectl apply -f redis-statefulset.yml -n $NAMESPACE

# Apply Deployments
echo "Applying Deployments..."
kubectl apply -f openim-api-deployment.yml -n $NAMESPACE
kubectl apply -f openim-crontask-deployment.yml -n $NAMESPACE
kubectl apply -f openim-msggateway-deployment.yml -n $NAMESPACE
kubectl apply -f openim-msgtransfer-deployment.yml -n $NAMESPACE
kubectl apply -f openim-push-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-auth-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-conversation-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-friend-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-group-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-msg-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-third-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-user-deployment.yml -n $NAMESPACE

# Apply Ingress
echo "Applying Ingress..."
kubectl apply -f ingress.yml -n $NAMESPACE

echo "OpenIM Server Deployment completed successfully!"
echo "You can check the status with: kubectl get pods -n $NAMESPACE"
echo "Access the API at: http://your-ingress-host/openim-api"
echo "Access the Message Gateway at: http://your-ingress-host/openim-msggateway"