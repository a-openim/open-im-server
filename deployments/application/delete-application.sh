#!/bin/bash

# OpenIM Application Deletion Script
# This script deletes all Kubernetes resources for OpenIM application components

set -e  # Exit on any error

echo "Starting OpenIM application deletion..."

NAMESPACE="openim"

# Delete OpenIM Deployments first
echo "Deleting OpenIM deployments..."
kubectl delete -f openim-api-deployment.yml -n $NAMESPACE
kubectl delete -f openim-crontask-deployment.yml  
kubectl delete -f openim-msggateway-deployment.yml -n $NAMESPACE
kubectl delete -f openim-msgtransfer-deployment.yml -n $NAMESPACE
kubectl delete -f openim-push-deployment.yml -n $NAMESPACE
kubectl delete -f openim-rpc-auth-deployment.yml -n $NAMESPACE
kubectl delete -f openim-rpc-conversation-deployment.yml -n $NAMESPACE
kubectl delete -f openim-rpc-friend-deployment.yml -n $NAMESPACE
kubectl delete -f openim-rpc-group-deployment.yml -n $NAMESPACE
kubectl delete -f openim-rpc-msg-deployment.yml -n $NAMESPACE
kubectl delete -f openim-rpc-third-deployment.yml -n $NAMESPACE
kubectl delete -f openim-rpc-user-deployment.yml -n $NAMESPACE

# Delete OpenIM Services
echo "Deleting OpenIM services..."
kubectl delete -f openim-api-service.yml -n $NAMESPACE
kubectl delete -f openim-msggateway-service.yml -n $NAMESPACE
kubectl delete -f openim-msgtransfer-service.yml -n $NAMESPACE
kubectl delete -f openim-push-service.yml -n $NAMESPACE
kubectl delete -f openim-rpc-auth-service.yml -n $NAMESPACE
kubectl delete -f openim-rpc-conversation-service.yml -n $NAMESPACE
kubectl delete -f openim-rpc-friend-service.yml -n $NAMESPACE
kubectl delete -f openim-rpc-group-service.yml -n $NAMESPACE
kubectl delete -f openim-rpc-msg-service.yml -n $NAMESPACE
kubectl delete -f openim-rpc-third-service.yml -n $NAMESPACE
kubectl delete -f openim-rpc-user-service.yml -n $NAMESPACE

# Delete Ingress
echo "Deleting ingress..."
kubectl delete -f ingress.yml -n $NAMESPACE

# Delete Infrastructure components
echo "Deleting configmap..."
kubectl delete -f openim-config.yml -n $NAMESPACE

echo "OpenIM application deletion completed successfully!"