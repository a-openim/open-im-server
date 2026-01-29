#!/bin/bash

# OpenIM Infrastructure Deployment Script
# This script applies Kubernetes resources for OpenIM infrastructure components

set -e  # Exit on any error

echo "Starting OpenIM infrastructure deployment..."

# Apply Secrets
echo "Applying secrets..."
kubectl apply -f redpanda-secret.yml
kubectl apply -f minio-secret.yml
kubectl apply -f mongo-secret.yml
kubectl apply -f redis-secret.yml

# Apply Services
echo "Applying services..."
kubectl apply -f redpanda-service.yml
kubectl apply -f minio-service.yml
kubectl apply -f mongo-service.yml
kubectl apply -f redis-service.yml

# Apply StatefulSets
echo "Applying statefulsets..."
kubectl apply -f redpanda-statefulset.yml
kubectl apply -f minio-statefulset.yml
kubectl apply -f mongo-statefulset.yml
kubectl apply -f redis-statefulset.yml

# Apply ConfigMap
echo "Applying configmap..."
kubectl apply -f openim-config.yml

# Apply Ingress
echo "Applying ingress..."
kubectl apply -f ingress.yml

echo "OpenIM infrastructure deployment completed successfully!"