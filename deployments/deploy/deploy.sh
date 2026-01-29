#!/bin/bash

# OpenIM Server Deployment Script
# This script deploys all OpenIM server components to a Kubernetes cluster

set -e

NAMESPACE=openim

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