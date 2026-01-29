#!/bin/bash

# OpenIM Server Cleanup Script
# This script removes all OpenIM server components from a Kubernetes cluster

set -e

NAMESPACE=openim

echo "Starting OpenIM Server Cleanup in namespace: $NAMESPACE"

# Delete Ingress
echo "Deleting Ingress..."
kubectl delete -f ingress.yml -n $NAMESPACE --ignore-not-found=true

# Delete Deployments
echo "Deleting Deployments..."
kubectl delete -f openim-api-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-crontask-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-msggateway-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-msgtransfer-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-push-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-auth-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-conversation-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-friend-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-group-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-msg-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-third-deployment.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-user-deployment.yml -n $NAMESPACE --ignore-not-found=true

# Delete StatefulSets
echo "Deleting StatefulSets..."
kubectl delete -f kafka-statefulset.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f minio-statefulset.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f mongo-statefulset.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f redis-statefulset.yml -n $NAMESPACE --ignore-not-found=true

# Delete services
echo "Deleting services..."
kubectl delete -f kafka-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f minio-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f mongo-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f redis-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-api-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-msggateway-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-msgtransfer-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-push-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-auth-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-conversation-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-friend-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-group-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-msg-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-third-service.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f openim-rpc-user-service.yml -n $NAMESPACE --ignore-not-found=true

# Delete ClusterRole and ClusterRoleBinding
echo "Deleting RBAC..."
kubectl delete -f clusterRole.yml -n $NAMESPACE --ignore-not-found=true

# Delete ConfigMap
echo "Deleting ConfigMap..."
kubectl delete -f openim-config.yml -n $NAMESPACE --ignore-not-found=true

# Delete secrets
echo "Deleting secrets..."
kubectl delete -f kafka-secret.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f minio-secret.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f mongo-secret.yml -n $NAMESPACE --ignore-not-found=true
kubectl delete -f redis-secret.yml -n $NAMESPACE --ignore-not-found=true

echo "OpenIM Server Cleanup completed successfully!"
echo "You can verify with: kubectl get all -n $NAMESPACE"