#!/bin/bash

# OpenIM Infrastructure Deletion Script
# This script deletes all Kubernetes resources for OpenIM infrastructure components

set -e  # Exit on any error

echo "Starting OpenIM infrastructure deletion..."

# Delete Infrastructure components
echo "Deleting configmap..."
kubectl delete -f openim-config.yml

echo "Deleting statefulsets..."
kubectl delete -f redpanda-statefulset.yml
kubectl delete -f minio-statefulset.yml
kubectl delete -f mongo-statefulset.yml
kubectl delete -f redis-statefulset.yml

echo "Deleting services..."
kubectl delete -f redpanda-service.yml
kubectl delete -f minio-service.yml
kubectl delete -f mongo-service.yml
kubectl delete -f redis-service.yml

echo "Deleting secrets..."
kubectl delete -f redpanda-secret.yml
kubectl delete -f minio-secret.yml
kubectl delete -f mongo-secret.yml
kubectl delete -f redis-secret.yml

echo "OpenIM infrastructure deletion completed successfully!"