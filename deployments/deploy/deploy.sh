#!/bin/bash

# OpenIM Kubernetes Deployment Script
# This script applies all Kubernetes resources for OpenIM in the correct order

set -e  # Exit on any error

echo "Starting OpenIM deployment..."

# Apply ClusterRole and ClusterRoleBinding
echo "Applying RBAC..."
kubectl apply -f clusterRole.yml

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

# Apply OpenIM Services
echo "Applying OpenIM services..."
kubectl apply -f openim-api-service.yml
kubectl apply -f openim-msggateway-service.yml
kubectl apply -f openim-msgtransfer-service.yml
kubectl apply -f openim-push-service.yml
kubectl apply -f openim-rpc-auth-service.yml
kubectl apply -f openim-rpc-conversation-service.yml
kubectl apply -f openim-rpc-friend-service.yml
kubectl apply -f openim-rpc-group-service.yml
kubectl apply -f openim-rpc-msg-service.yml
kubectl apply -f openim-rpc-third-service.yml
kubectl apply -f openim-rpc-user-service.yml

# Apply OpenIM Deployments
echo "Applying OpenIM deployments..."
kubectl apply -f openim-api-deployment.yml
kubectl apply -f openim-crontask-deployment.yml
kubectl apply -f openim-msggateway-deployment.yml
kubectl apply -f openim-msgtransfer-deployment.yml
kubectl apply -f openim-push-deployment.yml
kubectl apply -f openim-rpc-auth-deployment.yml
kubectl apply -f openim-rpc-conversation-deployment.yml
kubectl apply -f openim-rpc-friend-deployment.yml
kubectl apply -f openim-rpc-group-deployment.yml
kubectl apply -f openim-rpc-msg-deployment.yml
kubectl apply -f openim-rpc-third-deployment.yml
kubectl apply -f openim-rpc-user-deployment.yml

echo "OpenIM deployment completed successfully!"